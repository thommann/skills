---
name: event-system
description: >
  Reference for the project's eventing / messaging system — base event types, publishers and
  subscribers, topic conventions, delivery semantics. Use when user says 'how do events work',
  'event pattern', 'pub/sub', 'add a new event', 'what's the event bus', or 'how are messages
  routed'. Do NOT use for HTTP request/response (that's the API layer), for debugging missing
  events (use debug-backend), or for adding a specific event type (use the scaffolding skill).
allowed-tools: Read, Grep, Glob
---

# Event system — reference

<!--
  ADAPT TO YOUR PROJECT:
    {{BROKER}}            — NATS, Kafka, RabbitMQ, SQS, Redis Streams, in-process emitter, ...
    {{BASE_EVENT}}        — the project's event base class/interface: `src/events/base.ts`
    {{EVENTS_DIR}}        — `src/events/`, `packages/core/events/`
    {{PUBLISHER}}         — `src/events/publisher.ts` or equivalent
    {{SUBSCRIBER_BASE}}   — the subscriber base class, if any: `src/events/subscriber.ts`
    {{TOPIC_CONVENTION}}  — the project's subject/topic naming pattern
    {{EXEMPLAR_EVENT}}    — a recently-added event definition
    {{EXEMPLAR_HANDLER}}  — a recently-added subscriber handler
-->

## What this reference covers

The project's in-process or out-of-process event system: how events are defined, published, subscribed to, and delivered.

**NOT covered:**

- How {{BROKER}} works in general — read its docs.
- HTTP request/response — that's the API layer, not events.
- Debugging a missing or misrouted event — see `debug-backend`.
- Adding a new event type — that's a scaffolding skill workflow.

## Minimum-viable example

- **Event definition:** `{{EXEMPLAR_EVENT}}` — shape, base class, serialization.
- **Publisher side:** look at callers with `grep -rn 'publish.*{{ExemplarEventName}}' src/`.
- **Subscriber side:** `{{EXEMPLAR_HANDLER}}` — how the handler is wired and what it does.

Read these three files before doing anything event-adjacent.

## The contract

- **Base event:** `{{BASE_EVENT}}` — every event extends this. Required fields: typically `id`, `type`, `timestamp`, `correlation_id`. Project-specific: `tenant_id`, `user_id`, `trace_id`, etc.
- **Event families:** the project may distinguish:
  - **Control events** — internal orchestration (start, stop, health). Usually not persisted.
  - **Display events** — user-facing (surfaced in UI). Persisted; structured for rendering.
  - **Domain events** — business state changes (`UserSignedUp`, `OrderPlaced`). Persisted as the system-of-record for their subject.
  - Check `{{EVENTS_DIR}}/` for the subclasses in use.
- **Topic / subject convention:** `{{TOPIC_CONVENTION}}` — e.g., `<scope>.<entity>.<id>.<event-type>`. Every subscriber matches a pattern; matching is precise and case-sensitive.
- **Delivery semantics:**
  - **At-least-once:** the default for most brokers. Handlers must be idempotent.
  - **Ordering:** per-partition (Kafka), per-subject-within-stream (NATS), or none. Check which applies.
  - **Retention:** how long are events kept? This affects replay and recovery.

## Publisher

```
// Shape varies per project; the pattern is:
await {{PUBLISHER}}.publish(new {{YourEvent}}({...}))
```

Every `publish` call lives in a service, rarely in a controller directly. Publishing from a controller couples HTTP concerns to event semantics.

## Subscriber

Subscribers inherit from `{{SUBSCRIBER_BASE}}` (if the project has one) or register via a helper:

```
// See {{EXEMPLAR_HANDLER}} for the exact pattern
subscriber.on('{{topic-pattern}}', async (event) => {
  // idempotent handler body
});
```

**Rules every subscriber follows:**

- **Idempotent.** The same event can arrive twice. Use a dedup key (event.id) OR design the handler so re-processing is safe.
- **Bounded work.** A handler that takes minutes starves the subscriber. Offload to a queue or background task.
- **Typed.** Parse the event payload against a schema at the boundary. Don't trust `event.payload.x` without validation.
- **Failure policy.** Decide whether a handler error means retry (broker redelivers) or drop-and-alert. Document the choice in the handler file.

## Extension points

### Adding a new event type

1. See the project's scaffolding skill for events.
2. Extend the right base class (Control / Display / Domain).
3. Add the event to `{{EVENTS_DIR}}/`; register in the event registry if there is one.
4. For persisted events: update storage schema and the persistence handler.

### Adding a new subscriber

1. New handler file under `{{EVENTS_DIR}}/subscribers/` (or wherever the project keeps them).
2. Subscribe to the right topic pattern.
3. Handle idempotency (step above).
4. Test with a replayed event.

## Common pitfalls

| Pitfall | Correction |
|---|---|
| Publishing from a controller, bypassing the service layer | Call the service; the service publishes. Keeps controllers HTTP-only. |
| Subscriber that mutates shared state without idempotency | At-least-once means duplicates. Use a dedup key (event.id). |
| Relying on event order across topics | Ordering is per-partition/per-subject. Cross-topic order is not guaranteed. |
| Blocking I/O in a subscriber | Subscribers are in a critical delivery path. Offload slow work to a background queue. |

## Source of truth

- **Base event:** `{{BASE_EVENT}}`
- **Events directory:** `{{EVENTS_DIR}}`
- **Publisher helper:** `{{PUBLISHER}}`
- **Subscriber base:** `{{SUBSCRIBER_BASE}}`
- **Broker config:** `{{BROKER_CONFIG_FILE}}` (if any)
- **ADRs:** grep `docs/adr/` for `event` / `message` / the broker's name.

## Verify

```bash
for p in {{BASE_EVENT}} {{EVENTS_DIR}} {{PUBLISHER}} {{SUBSCRIBER_BASE}} {{EXEMPLAR_EVENT}} {{EXEMPLAR_HANDLER}}; do
  [ -e "$p" ] || echo "STALE: $p"
done
```

## Common Mistakes

| Mistake | Correction |
|---|---|
| Documenting "events are synchronous" when the broker is async | Asynchronicity is the default for {{BROKER}}. Document the delivery semantics honestly. |
| Assuming exactly-once because the broker claims to support it | Practical exactly-once usually means "at-least-once + idempotent handlers." Write handlers as if every event may arrive twice. |
| Topic conventions that drift from the code | Every subscriber's topic string should match a convention stated here. If convention and code disagree, code wins; update this skill. |
| Treating in-process emitter as a bus | In-process emitters lack delivery guarantees and persistence. If you need those, use a real broker. |
