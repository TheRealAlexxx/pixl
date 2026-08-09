import { db } from "../db/client.js";

export let programMemory: string[] = [];

export async function loadProgramMemory(): Promise<void> {
  try {
    const { data } = await db().from("program_memory").select("fact").order("id");
    programMemory = (data || []).map((r) => r.fact);
  } catch (e) {
    programMemory = [];
  }
}

export async function addProgramFact(fact: string): Promise<void> {
  await db().from("program_memory").insert({ fact });
  programMemory.push(fact);
}

export async function removeProgramFact(idx: number): Promise<void> {
  const fact = programMemory[idx];
  await db().from("program_memory").delete().eq("fact", fact);
  programMemory.splice(idx, 1);
}
