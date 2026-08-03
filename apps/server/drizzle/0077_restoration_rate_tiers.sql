-- Restoration rate tiers (src/xp.ts RATE_TIERS): the Blahaj trophy now pairs
-- with the new $6/hr rare top tier at 500 lifetime approved hours, up from
-- the old 100h/$5.53 ceiling.
update shop_items set unlock_xp = 500 where name ilike '%blahaj%';

-- New community goal: Gabin's payoff once the community crosses 1000 hours
-- of combined Restoration Energy. Sits between the existing "Great Forge"
-- (750) and "Vault Zero" (1800) goals in display order.
-- NOTE: energy_required is a starting estimate ("~1000h shipped", per Ridit) -
-- sanity check it against the live total at /api/vault and adjust via the
-- Community Goals admin page if it's already been passed or is too far off.
update vault_levels set position = position + 1 where level >= 3;

insert into vault_levels (level, energy_required, title, blurb, rewards, position) values
  (6, 1000, 'The Hall of Mirrors', 'Gabin loses a bet to the community and has to make good on it.',
    '[{"icon":"🧹","label":"Gabin in a maid outfit (photo/video, posted publicly)"}]'::jsonb, 3)
on conflict (level) do nothing;
