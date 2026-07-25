import Link from "next/link";
import { redirect } from "next/navigation";
import { requireSuper } from "@/lib/guard";
import { listShopOrders, ORDER_STAGES, type ShopOrderRow, type OrderStatus } from "@/lib/db";
import { slackHandles } from "@/lib/slack";
import { claimOrder, markOrderCredited, shipOrder, reassignOrder, cancelOrder } from "@/app/actions";
import { PendingButton } from "@/app/_components/PendingButton";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Input } from "@/components/ui/input";

export const dynamic = "force-dynamic";

const STATUS_BADGE: Record<OrderStatus, "secondary" | "success" | "destructive" | "warning"> = {
  pending: "secondary",
  ordered: "warning",
  credited: "warning",
  shipped: "success",
  cancelled: "destructive",
};

// Human labels for the four live stages, in pipeline order.
const STAGE_LABEL: Record<OrderStatus, string> = {
  pending: "New",
  ordered: "Ordered",
  credited: "Credited",
  shipped: "Shipped",
  cancelled: "Cancelled",
};

function slackLink(id: string): string {
  return `https://slack.com/app_redirect?channel=${id}`;
}

const TAB_KEYS = ["pending", "ordered", "credited", "shipped", "cancelled", "all"] as const;
type TabKey = (typeof TAB_KEYS)[number];

export default async function FulfillmentPage({
  searchParams,
}: {
  searchParams: Promise<{ status?: string; mine?: string }>;
}) {
  const access = await requireSuper();
  if (!access.isSuper) redirect("/");
  const me = access.session.slackId;
  const { status, mine } = await searchParams;
  const active: TabKey = TAB_KEYS.includes(status as TabKey) ? (status as TabKey) : "pending";
  const mineOnly = mine === "1";

  let orders = await listShopOrders(active === "all" ? undefined : active, 500);
  if (mineOnly) orders = orders.filter((o) => o.claimed_by_slack === me);
  const pendingCount =
    active === "pending" && !mineOnly
      ? orders.length
      : (await listShopOrders("pending", 1)).length;
  const handles = await slackHandles(orders.map((o) => o.player_slack));

  const tabs: { key: TabKey; label: string }[] = [
    { key: "pending", label: "New" },
    { key: "ordered", label: "Ordered" },
    { key: "credited", label: "Credited" },
    { key: "shipped", label: "Shipped" },
    { key: "cancelled", label: "Cancelled" },
    { key: "all", label: "All" },
  ];

  const linkFor = (key: TabKey) => {
    const params = new URLSearchParams();
    if (key !== "pending") params.set("status", key);
    if (mineOnly) params.set("mine", "1");
    const qs = params.toString();
    return qs ? `/fulfillment?${qs}` : "/fulfillment";
  };
  const mineToggleLink = () => {
    const params = new URLSearchParams();
    if (active !== "pending") params.set("status", active);
    if (!mineOnly) params.set("mine", "1");
    const qs = params.toString();
    return qs ? `/fulfillment?${qs}` : "/fulfillment";
  };

  return (
    <div>
      <h1 className="text-2xl font-semibold text-foreground tracking-tight mb-1">Fulfillment</h1>
      <p className="text-sm text-muted-foreground mb-5 max-w-2xl">
        Orders players placed in the shop with pixels. Claim one to place the real order , it moves
        into your queue and walks through <em>ordered → credited → shipped</em>. Enter tracking when
        it ships and Pixo DMs it to the buyer. Cancel any time before it ships to refund the pixels.
      </p>

      <div className="flex items-center gap-3 flex-wrap mb-4">
        <div className="inline-flex items-center rounded-lg border border-border p-0.5 bg-card">
          {tabs.map((t) => (
            <Button
              key={t.key}
              asChild
              variant="ghost"
              size="sm"
              className={active === t.key ? "bg-primary text-primary-foreground hover:bg-primary/90 hover:text-primary-foreground" : ""}
            >
              <Link href={linkFor(t.key)}>
                {t.label}
                {t.key === "pending" && pendingCount > 0 ? ` (${pendingCount})` : ""}
              </Link>
            </Button>
          ))}
        </div>
        <Button
          asChild
          variant={mineOnly ? "default" : "outline"}
          size="sm"
          className={mineOnly ? "bg-brand text-white hover:bg-brand/90 hover:text-white border-transparent" : ""}
        >
          <Link href={mineToggleLink()}>{mineOnly ? "My queue ✓" : "My queue"}</Link>
        </Button>
      </div>

      {orders.length === 0 ? (
        <Card className="p-8 text-center text-muted-foreground text-sm">
          {active === "pending"
            ? "No orders waiting to be claimed. Nice and clear."
            : mineOnly
              ? "Nothing in your queue here."
              : "Nothing here yet."}
        </Card>
      ) : (
        <div className="grid gap-3">
          {orders.map((o) => (
            <OrderCard
              key={o.id}
              order={o}
              handle={o.player_slack ? handles.get(o.player_slack) : undefined}
              mine={o.claimed_by_slack === me}
            />
          ))}
        </div>
      )}
    </div>
  );
}

// The four live stages as a stepper, current one lit. Cancelled orders skip it.
function StageSteps({ status }: { status: OrderStatus }) {
  if (status === "cancelled") return null;
  const idx = ORDER_STAGES.indexOf(status);
  return (
    <div className="flex items-center gap-1.5 text-xs">
      {ORDER_STAGES.map((s, i) => (
        <span key={s} className="flex items-center gap-1.5">
          <span
            className={
              i < idx
                ? "text-muted-foreground"
                : i === idx
                  ? "font-semibold text-brand"
                  : "text-muted-foreground/40"
            }
          >
            {STAGE_LABEL[s]}
          </span>
          {i < ORDER_STAGES.length - 1 && <span className="text-muted-foreground/30">→</span>}
        </span>
      ))}
    </div>
  );
}

function fmtDate(iso: string | null): string {
  return iso ? new Date(iso).toLocaleDateString() : "";
}

function OrderCard({ order: o, handle, mine }: { order: ShopOrderRow; handle?: string; mine: boolean }) {
  const live = o.status !== "shipped" && o.status !== "cancelled";
  return (
    <Card className="p-4 gap-3">
      <div className="flex items-start justify-between gap-3 flex-wrap">
        <div className="min-w-0">
          <div className="flex items-center gap-2 flex-wrap">
            <span className="font-semibold">{o.item_name || "(item removed)"}</span>
            <Badge variant="success" className="tabular-nums">
              {o.price} px
            </Badge>
            <Badge variant={STATUS_BADGE[o.status] ?? "secondary"} className="capitalize">
              {STAGE_LABEL[o.status] ?? o.status}
            </Badge>
            {o.option && <Badge variant="secondary">{o.option}</Badge>}
          </div>
          <div className="text-sm text-muted-foreground mt-1">
            <Link href={`/players/${o.user_id}`} className="font-medium text-foreground hover:text-brand">
              {o.player_name}
            </Link>
            {o.player_slack && (
              <>
                {" · "}
                <a href={slackLink(o.player_slack)} target="_blank" rel="noreferrer" className="hover:text-brand">
                  {handle ?? o.player_slack}
                </a>
              </>
            )}
            {" · "}
            {new Date(o.created_at).toLocaleString()}
          </div>
          {o.claimed_by && o.status !== "pending" && (
            <div className="text-xs text-muted-foreground mt-1">
              {o.status === "cancelled" ? "Handled" : o.status === "shipped" ? "Fulfilled" : "Claimed"} by{" "}
              <span className="text-foreground">{o.claimed_by}</span>
              {mine && live ? " (you)" : ""}
              {o.status === "shipped" && o.shipped_at ? ` · shipped ${fmtDate(o.shipped_at)}` : ""}
            </div>
          )}
          {o.status === "shipped" && o.tracking && (
            <div className="text-xs text-muted-foreground mt-1">
              Tracking: <span className="text-foreground font-mono">{o.tracking}</span> · DM&apos;d to buyer
            </div>
          )}
          {o.status === "cancelled" && o.note && (
            <div className="text-xs text-muted-foreground mt-1">{o.note}</div>
          )}
        </div>
        <StageSteps status={o.status} />
      </div>

      {live && <OrderActions order={o} mine={mine} />}
    </Card>
  );
}

function OrderActions({ order: o, mine }: { order: ShopOrderRow; mine: boolean }) {
  const cancelForm = (
    <form action={cancelOrder}>
      <input type="hidden" name="id" value={o.id} />
      <PendingButton
        variant="outline"
        pendingText="Refunding…"
        confirm={`Cancel this order and refund ${o.price} pixels to ${o.player_name}?`}
        className="text-rose-600 border-rose-200 dark:border-rose-500/30 hover:bg-rose-50 dark:hover:bg-rose-500/10 hover:text-rose-600"
      >
        Cancel &amp; refund
      </PendingButton>
    </form>
  );

  // Claimed by someone else: offer to take it over rather than acting on their queue.
  if (!mine && o.status !== "pending") {
    return (
      <div className="flex items-end gap-2 flex-wrap">
        <form action={reassignOrder}>
          <input type="hidden" name="id" value={o.id} />
          <PendingButton variant="outline" pendingText="Taking over…">
            Reassign to me
          </PendingButton>
        </form>
        {cancelForm}
      </div>
    );
  }

  if (o.status === "pending") {
    return (
      <div className="flex items-end gap-2 flex-wrap">
        <form action={claimOrder}>
          <input type="hidden" name="id" value={o.id} />
          <PendingButton className="bg-brand text-white border-transparent" pendingText="Claiming…">
            Place order &amp; claim
          </PendingButton>
        </form>
        {cancelForm}
      </div>
    );
  }

  if (o.status === "ordered") {
    return (
      <div className="flex items-end gap-2 flex-wrap">
        <form action={markOrderCredited}>
          <input type="hidden" name="id" value={o.id} />
          <PendingButton className="bg-brand text-white border-transparent" pendingText="Saving…">
            Mark credited (receipt uploaded)
          </PendingButton>
        </form>
        {cancelForm}
      </div>
    );
  }

  // credited -> ship with a required tracking number.
  return (
    <div className="flex items-end gap-2 flex-wrap">
      <form action={shipOrder} className="flex items-end gap-2 flex-1 min-w-64">
        <input type="hidden" name="id" value={o.id} />
        <label className="block flex-1 min-w-0">
          <span className="block text-xs font-medium text-muted-foreground mb-1">
            Tracking number (DM&apos;d to the buyer)
          </span>
          <Input name="tracking" maxLength={120} required placeholder="1Z…" className="w-full text-sm" />
        </label>
        <PendingButton className="bg-brand text-white border-transparent" pendingText="Shipping…">
          Mark shipped
        </PendingButton>
      </form>
      {cancelForm}
    </div>
  );
}
