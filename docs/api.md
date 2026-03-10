# API Contract

## Endpoint

`POST /api/excuses/generate`

## Request

```json
{
  "truth": "I'm late because I was on the toilet",
  "style": "goofy"
}
```

## Response

```json
{
  "excuse": "A raccoon unionized the plumbing and I got trapped in negotiations.",
  "detectedLanguage": "en",
  "style": "goofy"
}
```

## Validation rules

- `truth` is required
- `truth` must be between 1 and 240 characters after trimming
- `style` must be `goofy` or `serious`

## Error responses

### 422 validation error

Returned when the request body is missing valid values.

### 502 upstream failure

```json
{
  "detail": "The alibi engine failed upstream."
}
```

### 504 timeout

```json
{
  "detail": "The alibi engine timed out."
}
```
