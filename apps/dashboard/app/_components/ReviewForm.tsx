"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import { useFormStatus } from "react-dom";
import { reviewProject } from "@/app/actions";
import { TECHNICAL_FEATURES_MIN } from "@/lib/auditNote";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import { Checkbox } from "@/components/ui/checkbox";

function VerdictButtons({ secondPass }: { secondPass: boolean }) {
  const { pending } = useFormStatus();
  const [clicked, setClicked] = useState("");
  const approveLabel = secondPass ? "Approve & credit pixels" : "Approve";
  return (
    <>
      <Button
        name="verdict"
        value="approved"
        disabled={pending}
        onClick={() => setClicked("approved")}
        className="bg-emerald-600 text-white hover:bg-emerald-700"
      >
        {pending && clicked === "approved" ? "Approving…" : approveLabel}
      </Button>
      <Button
        name="verdict"
        value="needs_changes"
        disabled={pending}
        onClick={() => setClicked("needs_changes")}
        className="bg-red-600 text-white hover:bg-red-700"
      >
        {pending && clicked === "needs_changes" ? "Sending back…" : "Request changes"}
      </Button>
      <Button
        name="verdict"
        value="ban"
        disabled={pending}
        onClick={() => setClicked("ban")}
        variant="outline"
        className="border-red-700 text-red-700 hover:bg-red-50 dark:hover:bg-red-950/30"
      >
        {pending && clicked === "ban"
          ? secondPass
            ? "Banning…"
            : "Proposing…"
          : secondPass
            ? "Ban project"
            : "Propose ban"}
      </Button>
    </>
  );
}

export interface BountyOption {
  id: number;
  name: string;
  reward: number;
  description: string;
}

export interface TrialInfo {
  name: string;
  minHours: number | null;
}

export function ReviewForm({
  projectId,
  repoUrl,
  demoUrl,
  claimedHours,
  defaultHours,
  secondPass = false,
  bounties = [],
  trial,
  hackatimeProjects = [],
  hackatimeSeconds = 0,
  ageFlag = false,
}: {
  projectId: number;
  repoUrl: string | null;
  demoUrl: string | null;
  claimedHours: number;
  defaultHours?: number;
  secondPass?: boolean;
  bounties?: BountyOption[];
  trial?: TrialInfo | null;
  hackatimeProjects?: string[];
  hackatimeSeconds?: number;
  ageFlag?: boolean;
}) {
  const repoOpened = useRef<HTMLInputElement>(null);
  const demoOpened = useRef<HTMLInputElement>(null);
  const repoSeconds = useRef<HTMLInputElement>(null);
  const demoSeconds = useRef<HTMLInputElement>(null);
  const totalSeconds = useRef<HTMLInputElement>(null);
  const away = useRef<{ kind: "repo" | "demo"; at: number } | null>(null);
  const openedAt = useRef(Date.now());

  const baseHours = defaultHours ?? claimedHours;
  const [hours, setHours] = useState(baseHours);
  const deflated = hours < claimedHours;

  const hackatimeDefault = useMemo(() => {
    if (hackatimeSeconds <= 0) return "";
    const h = Math.round((hackatimeSeconds / 3600) * 10) / 10;
    const names = hackatimeProjects.length ? hackatimeProjects.join(", ") : "(unnamed)";
    return `${names} , ${h}h tracked (see the Hackatime tab for the date range).`;
  }, [hackatimeProjects, hackatimeSeconds]);

  const [featuresLen, setFeaturesLen] = useState(0);

  useEffect(() => {
    openedAt.current = Date.now();
    const settle = () => {
      const a = away.current;
      if (!a || document.visibilityState !== "visible") return;
      away.current = null;
      const el = a.kind === "repo" ? repoSeconds.current : demoSeconds.current;
      if (el)
        el.value = String(
          Math.round(Number(el.value || 0) + (Date.now() - a.at) / 1000),
        );
    };
    window.addEventListener("focus", settle);
    document.addEventListener("visibilitychange", settle);
    return () => {
      window.removeEventListener("focus", settle);
      document.removeEventListener("visibilitychange", settle);
    };
  }, []);

  const markOpen = (kind: "repo" | "demo") => {
    const el = kind === "repo" ? repoOpened.current : demoOpened.current;
    if (el) el.value = "1";
    away.current = { kind, at: Date.now() };
  };

  return (
    <form
      action={reviewProject}
      onSubmit={() => {
        if (totalSeconds.current)
          totalSeconds.current.value = String(
            Math.round((Date.now() - openedAt.current) / 1000),
          );
      }}
      className="mt-4 flex flex-col gap-4"
    >
      <input type="hidden" name="projectId" value={projectId} />
      <input type="hidden" name="repoOpened" defaultValue="0" ref={repoOpened} />
      <input type="hidden" name="demoOpened" defaultValue="0" ref={demoOpened} />
      <input type="hidden" name="repoSeconds" defaultValue="0" ref={repoSeconds} />
      <input type="hidden" name="demoSeconds" defaultValue="0" ref={demoSeconds} />
      <input type="hidden" name="totalSeconds" defaultValue="0" ref={totalSeconds} />
      <div className="flex flex-wrap gap-2 items-center text-sm font-bold">
        {repoUrl && (
          <Button asChild variant="secondary">
            <a
              href={repoUrl}
              target="_blank"
              rel="noreferrer"
              onClick={() => markOpen("repo")}
            >
              Repo
            </a>
          </Button>
        )}
        {demoUrl && (
          <Button asChild variant="secondary">
            <a
              href={demoUrl}
              target="_blank"
              rel="noreferrer"
              onClick={() => markOpen("demo")}
            >
              Demo
            </a>
          </Button>
        )}
      </div>
      <Label className="flex items-center justify-between gap-2 font-normal text-muted-foreground">
        Hours to credit (decrease only)
        <Input
          name="approvedHours"
          type="number"
          step="0.1"
          min="0"
          max={claimedHours}
          value={hours}
          onChange={(e) => setHours(Math.min(claimedHours, Math.max(0, Number(e.target.value) || 0)))}
          className="w-28 text-sm"
        />
      </Label>
      {trial?.minHours != null && (
        <div
          className={`text-xs font-medium ${
            hours < trial.minHours
              ? "text-red-600 dark:text-red-400"
              : "text-muted-foreground"
          }`}
        >
          Trial &quot;{trial.name}&quot; needs {trial.minHours}h minimum to approve
          {hours < trial.minHours ? " , credited hours are below that, so Approve will be blocked." : "."}
        </div>
      )}
      {bounties.length > 0 && (
        <div className="rounded-lg border border-amber-200 dark:border-amber-500/30 bg-amber-50/60 dark:bg-amber-500/[0.06] p-3">
          <div className="text-xs font-bold uppercase tracking-wide text-amber-700 dark:text-amber-300 mb-1.5">
            Bounty board , tick what this project meets (paid on final approval)
          </div>
          {bounties.map((b) => (
            <Label key={b.id} className="flex items-start gap-2 text-sm py-0.5 font-normal">
              <Checkbox name="bountyIds" value={String(b.id)} className="mt-0.5" />
              <span>
                {b.name} <span className="font-semibold">+{b.reward} px</span>
                {b.description && <span className="text-muted-foreground"> , {b.description}</span>}
              </span>
            </Label>
          ))}
        </div>
      )}
      <div className="rounded-lg border p-4 flex flex-col gap-4">
        <div className="text-xs font-bold uppercase tracking-wide text-muted-foreground leading-relaxed">
          Internal audit note , never shown to the player. Should let someone who
          wasn&apos;t involved reach the same conclusion you did.
        </div>
        <div>
          <Label className="text-xs font-normal text-muted-foreground mb-1.5 block leading-relaxed">
            Technical features , concrete accomplishments, not generic (&quot;OAuth
            auth, REST API, self-hosted Postgres&quot;, not &quot;React&quot;)
          </Label>
          <div className="relative">
            <Textarea
              name="technicalFeatures"
              required
              minLength={TECHNICAL_FEATURES_MIN}
              onChange={(e) => setFeaturesLen(e.target.value.trim().length)}
              placeholder="What did you actually check in the repo/demo?"
              className="w-full text-sm pb-5"
              rows={3}
            />
            <span
              className={`pointer-events-none absolute bottom-1.5 right-2 text-[10px] tabular-nums ${
                featuresLen >= TECHNICAL_FEATURES_MIN ? "text-emerald-500" : "text-muted-foreground"
              }`}
            >
              {featuresLen}/{TECHNICAL_FEATURES_MIN}
            </span>
          </div>
        </div>
        {hackatimeSeconds > 0 && (
          <div>
            <Label className="text-xs font-normal text-muted-foreground mb-1.5 block">
              Hackatime evidence
            </Label>
            <Textarea
              name="hackatimeEvidence"
              defaultValue={hackatimeDefault}
              className="w-full text-sm"
              rows={3}
            />
          </div>
        )}
        {deflated && (
          <div>
            <Label className="text-xs font-normal text-muted-foreground mb-1.5 block">
              Why lower the hours? ({claimedHours}h claimed → {hours}h credited)
            </Label>
            <Textarea
              name="deflationReason"
              required
              placeholder="Mismatched experience/features, missing commits, etc."
              className="w-full text-sm"
              rows={3}
            />
          </div>
        )}
        {ageFlag && (
          <div>
            <Label className="text-xs font-normal text-muted-foreground mb-1.5 block leading-relaxed">
              Age justification , this submitter turns 19 between shipping and this
              review
            </Label>
            <Textarea
              name="ageJustification"
              required
              placeholder="Document the submitter's age at shipping vs. now."
              className="w-full text-sm"
              rows={3}
            />
          </div>
        )}
        <div>
          <Label className="text-xs font-normal text-muted-foreground mb-1.5 block">
            Additional notes (optional)
          </Label>
          <Textarea
            name="notes"
            placeholder="Anything else , suspicious commits, AI usage, experience mismatch…"
            className="w-full text-sm"
            rows={3}
          />
        </div>
      </div>
      <div className="flex flex-col gap-2">
        <Textarea
          name="note"
          required
          placeholder="Feedback for the player (required)"
          className="w-full text-sm"
          rows={3}
        />
        <div className="flex flex-wrap gap-2">
          <VerdictButtons secondPass={secondPass} />
        </div>
      </div>
    </form>
  );
}
