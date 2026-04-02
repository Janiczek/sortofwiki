# SortOfWiki Product User Stories

## 1) Opinionated URL Map

- `/` - public homepage with hosted wiki catalog
- `/w/:wikiSlug` - wiki homepage (latest activity, key navigation)
- `/w/:wikiSlug/pages` - page index
- `/w/:wikiSlug/p/:pageSlug` - published page view
- `/w/:wikiSlug/register` - register as wiki contributor
- `/w/:wikiSlug/login` - login
- `/w/:wikiSlug/submit/new` - submit a new page draft for review (story 9)
- `/w/:wikiSlug/submit/edit/:pageSlug` - propose an edit to a published page (story 10)
- `/w/:wikiSlug/submit/delete/:pageSlug` - request deletion of a published page (story 11)
- `/w/:wikiSlug/submit/:submissionId` - contributor submission detail
- `/w/:wikiSlug/review` - review queue for trusted contributors and admins
- `/w/:wikiSlug/review/:submissionId` - review detail and decision screen
- `/w/:wikiSlug/admin` - wiki admin landing
- `/w/:wikiSlug/admin/users` - role and trust management
- `/w/:wikiSlug/admin/audit` - audit log
- `/w/:wikiSlug/settings/profile` - user profile for this wiki
- `/admin` - hidden platform host-admin entry point
- `/admin/wikis` - host-admin wiki management list
- `/admin/wikis/new` - create new hosted wiki
- `/admin/wikis/:wikiSlug` - hosted wiki metadata and lifecycle controls

## 3) MVP User Stories (Numbered)

1. [x] Viewer can open `/` and see a list of hosted wikis so that they can discover available communities.
2. [x] Viewer can open `/w/:wikiSlug` so that they can access a specific wiki.
3. [x] Viewer can open `/w/:wikiSlug/pages` so that they can browse published pages.
4. [x] Viewer can open `/w/:wikiSlug/p/:pageSlug` so that they can read published content.
5. [x] Viewer can see backlinks on a page so that they can find related pages.
6. [x] Viewer can only see published revisions so that unreviewed changes are not exposed.
7. [x] Contributor can register at `/w/:wikiSlug/register` so that they can submit page changes.
8. [x] Contributor can log in at `/w/:wikiSlug/login` so that their submissions are attributed to them.
9. [x] Contributor can submit a new page draft so that it can be reviewed.
10. [x] Contributor can submit edits to an existing page so that they can improve content.
11. [x] Contributor can request page deletion through a submission so that removals are moderated.
12. [x] Contributor can view submission status so that they know whether a change is pending, approved, rejected, or needs revision. Seeded demo: log in on `demo` as `statusdemo` / `password12` and open `/w/demo/submit/sub_rejected_demo`, `/w/demo/submit/sub_approved_demo`, or `/w/demo/submit/sub_needs_revision_demo` to see non-pending statuses.
13. [x] Contributor can read reviewer notes on rejected or revision-requested submissions so that they can improve and resubmit. Seeded demo: same as story 12 login; rejected submission `sub_rejected_demo` includes a reviewer note; `sub_needs_revision_demo` includes guidance text.
14. [x]  Trusted contributor can publish page create/edit/delete changes immediately so that routine maintenance is fast. Seeded demo: log in on `demo` as `trustedpub` / `password12` to publish directly; standard contributors still go through review.
15. [x]  Trusted contributor can open `/w/:wikiSlug/review` so that they can process pending submissions. Seeded demo: log in on `demo` as `trustedpub` / `password12` and open `/w/demo/review` to see pending submission `sub_queue_demo` from standard user `statusdemo`.
16. [x]  Trusted contributor can inspect submission diffs so that they can make informed moderation decisions.
17. [x]  Trusted contributor can approve a submission so that it goes live.
18. [x]  Trusted contributor can reject a submission with a reason so that harmful or low-quality changes are blocked.
19. [x]  Trusted contributor can request changes with guidance so that contributors can iterate.
20. [x]  Wiki admin can open `/w/:wikiSlug/admin/users` so that they can manage contributor trust levels. Seeded demo: log in on `demo` as `wikidemo` / `password12` and open `/w/demo/admin/users` to see contributors (`statusdemo`, `trustedpub`, `grantadmin_trusted`, `wikidemo`) and roles.
21. [x]  Wiki admin can promote an editor to trusted contributor so that reliable editors can publish directly.
22. [x]  Wiki admin can demote a trusted contributor to contributor so that risky behavior can be contained.
23. [x]  Wiki admin can grant admin rights to another trusted contributor so that governance can be shared. Seeded demo: on `demo`, trusted user `grantadmin_trusted` / `password12` exists to be promoted to admin from `/w/demo/admin/users` (story 23); wiki admin `wikidemo` can use **Make admin** on that row.
24. [x]  Wiki admin can revoke admin rights so that incorrect access can be corrected. Seeded demo: on `demo`, log in as `wikidemo` / `password12`, open `/w/demo/admin/users`, use **Make admin** on `grantadmin_trusted` if they are still trusted, then **Revoke admin** on that row; they become trusted again. Server-side listing uses `WikiContributors.isAdminForWiki` (trusted users do not pass).
25. [x]  Wiki admin can open `/w/:wikiSlug/admin/audit` so that they can see what changed and by whom.
26. [x]  Wiki admin can filter audit events by actor, page, and event type so that they can investigate incidents.
27. [x]  Platform host admin can authenticate at `/admin` using the hidden URL and password so that platform operations remain restricted.
28. [x]  Platform host admin can open `/admin/wikis` and see all hosted wikis so that they can manage the catalog.
29. [x]  Platform host admin can create a hosted wiki so that new communities can be launched.
30. [x]  Platform host admin can edit hosted wiki metadata (name, summary, slug policy) so that discoverability stays accurate.
31. [x]  Platform host admin can deactivate a hosted wiki so that unsafe or inactive tenants can be paused without data loss.
32. [x]  Platform host admin can delete a hosted wiki through explicit confirmation so that irreversible operations are deliberate and auditable.
33. [x]  As any authenticated role, my authorization is checked server-side so that direct URL access cannot bypass permissions.
34. [x]  As an admin or trusted contributor, all moderation decisions are logged with actor and timestamp so that governance is accountable.
35. [x] Viewer can open an unknown URL and see a 404 page so that broken or mistyped links are clearly not valid content.
46. [x] Viewer sees `[[page-slug]]` and `[[page-slug|label]]` in published markdown as links to that page on the current wiki (same `/w/:wikiSlug/p/...` URL space).

## 4) Post-MVP User Stories (Numbered)

36. [ ] Viewer can search pages within a wiki so that they can quickly find relevant pages.
37. [ ] Viewer can sort wiki catalog entries by activity so that they can find active communities.
38. [ ] Contributor can receive in-app notifications for review decisions so that they do not need to poll manually.
39. [ ] Trusted contributor can view moderation workload metrics so that review throughput can be balanced.
40. [ ] Wiki admin can suspend or ban abusive users so that repeated abuse can be controlled quickly.
41. [ ] Wiki admin can export audit logs so that compliance and external review are possible.
42. [ ] Wiki admin can restore deleted pages from a retention window so that mistakes are reversible.
43. [ ] Platform host admin can enforce optional second-factor login so that host controls have stronger protection.
44. [ ] Platform host admin can mark wikis as public, unlisted, or private so that visibility policy is explicit.
45. [ ] Platform host admin can view cross-tenant health dashboards so that operational issues are detected early.

## 5) Graphviz Feature Dependency Graph

```dot
digraph SortOfWiki {
  rankdir=LR;
  graph [fontname="Helvetica", labelloc="t", label="SortOfWiki Feature Dependencies"];
  node [shape=box, style=filled, fontname="Helvetica", color="#2e2e2e"];
  edge [color="#666666", arrowsize=0.7];

  // Role color key:
  // Admin = #d9534f, Trusted = #f0ad4e, Contributor = #5bc0de, Anonymous = #5cb85c

  subgraph cluster_mvp {
    label="MVP";
    color="#9e9e9e";
    style="rounded";

    S5 [label="S5 Backlinks on page", fillcolor="#5cb85c"];
    S7 [label="S7 Register contributor", fillcolor="#5bc0de"];
    S8 [label="S8 Login contributor", fillcolor="#5bc0de"];
    S10 [label="S10 Submit page edit", fillcolor="#5bc0de"];
    S12 [label="S12 Track submission status", fillcolor="#5bc0de"];
    S14 [label="S14 Trusted direct publish", fillcolor="#f0ad4e"];
    S15 [label="S15 Review queue", fillcolor="#f0ad4e"];
    S17 [label="S17 Approve submission", fillcolor="#f0ad4e"];
    S18 [label="S18 Reject submission", fillcolor="#f0ad4e"];
    S19 [label="S19 Request changes", fillcolor="#f0ad4e"];
    S20 [label="S20 Admin users page", fillcolor="#d9534f"];
    S21 [label="S21 Promote trusted", fillcolor="#d9534f"];
    S22 [label="S22 Demote trusted", fillcolor="#d9534f"];
    S25 [label="S25 Audit log page", fillcolor="#d9534f"];
    S27 [label="S27 Host admin auth", fillcolor="#d9534f"];
    S28 [label="S28 Host wiki list", fillcolor="#d9534f"];
    S29 [label="S29 Create hosted wiki", fillcolor="#d9534f"];
    S31 [label="S31 Deactivate hosted wiki", fillcolor="#d9534f"];
    S32 [label="S32 Delete hosted wiki", fillcolor="#d9534f"];
    S33 [label="S33 Server-side authz", fillcolor="#d9534f"];
    S34 [label="S34 Moderation audit trail", fillcolor="#d9534f"];
  }

  // Non-MVP nodes outside cluster
  S36 [label="S36 Page search", fillcolor="#5cb85c"];
  S38 [label="S38 Review notifications", fillcolor="#5bc0de"];
  S39 [label="S39 Moderation metrics", fillcolor="#f0ad4e"];
  S40 [label="S40 Suspend/ban users", fillcolor="#d9534f"];
  S41 [label="S41 Audit export", fillcolor="#d9534f"];
  S42 [label="S42 Restore deleted pages", fillcolor="#d9534f"];
  S43 [label="S43 Host 2FA", fillcolor="#d9534f"];
  S44 [label="S44 Public/unlisted/private mode", fillcolor="#d9534f"];
  S45 [label="S45 Cross-tenant health dashboard", fillcolor="#d9534f"];

  // Core dependency edges
  S7 -> S8;
  S8 -> S10;
  S10 -> S12;
  S10 -> S15;

  S15 -> S17;
  S15 -> S18;
  S15 -> S19;
  S17 -> S4;
  S19 -> S10;

  S20 -> S21;
  S20 -> S22;
  S20 -> S25;

  S27 -> S28;
  S28 -> S29;
  S28 -> S31;
  S28 -> S32;

  S33 -> S10;
  S33 -> S14;
  S33 -> S15;
  S33 -> S20;
  S33 -> S27;

  S34 -> S25;
  S34 -> S15;

  // Post-MVP dependencies
  S12 -> S38;
  S15 -> S39;
  S20 -> S40;
  S25 -> S41;
  S32 -> S42;
  S27 -> S43;
  S28 -> S44;
  S28 -> S45;
}
```
