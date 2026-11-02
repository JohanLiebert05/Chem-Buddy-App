import {isGeminiCoolingDown, recordGeminiFailure} from './gemini_cooldown.ts';

export type RotationState = {activeIndex: number; cooldowns: Map<string, number>};
export async function rotateGemini(
  keys: string[], endpoint: string, payload: unknown, state: RotationState,
  options: {deadline?: number; attemptTimeoutMs?: number; send?: typeof fetch; now?: () => number} = {},
): Promise<{ok: boolean; status: number; data?: any; errorText?: string; keyIndexUsed?: number}> {
  const now = options.now ?? Date.now;
  const deadline = options.deadline ?? now() + 25000;
  const send = options.send ?? fetch;
  if (!keys.length) return {ok:false,status:503,errorText:'No Gemini credentials configured.'};
  const start = state.activeIndex % keys.length;
  let lastStatus = 503;
  let errorText = 'All configured keys are temporarily unavailable for this model.';
  for (let offset=0; offset<keys.length; offset++) {
    const index=(start+offset)%keys.length, key=keys[index];
    if (isGeminiCoolingDown(state.cooldowns,endpoint,key,now())) continue;
    const remaining=deadline-now();
    if (remaining<=0) return {ok:false,status:504,errorText:'AI request deadline reached.'};
    const controller=new AbortController();
    const timer=setTimeout(()=>controller.abort(),Math.min(options.attemptTimeoutMs ?? 6000,remaining));
    try {
      // Await each attempt: no speculative parallel generations or retry sleeps.
      const response=await send('https://generativelanguage.googleapis.com/v1beta/'+endpoint,{
        method:'POST',headers:{'Content-Type':'application/json','x-goog-api-key':key},
        body:JSON.stringify(payload),signal:controller.signal,
      });
      if (response.ok) {
        const data=await response.json();
        state.activeIndex=index;
        return {ok:true,status:response.status,data,keyIndexUsed:index+1};
      }
      lastStatus=response.status;
      recordGeminiFailure(state.cooldowns,endpoint,key,lastStatus,now());
      errorText=lastStatus===429?'Provider quota or rate limit reached.'
        :lastStatus===401||lastStatus===403?'Provider authentication or permission rejected.'
        :lastStatus===404?'Requested model unavailable.':'Provider temporarily unavailable.';
      // Do not retain or expose raw provider error bodies or credentials.
      try { await response.body?.cancel(); } catch { /* Already consumed/closed. */ }
    } catch {
      lastStatus=504;errorText='Provider request timed out or failed.';
    } finally { clearTimeout(timer); }
    state.activeIndex=(index+1)%keys.length;
  }
  return {ok:false,status:lastStatus,errorText};
}
