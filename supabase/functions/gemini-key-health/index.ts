import { keyHealth } from "./handler.ts";
Deno.serve((req: Request) => keyHealth(req, (name) => Deno.env.get(name)));
