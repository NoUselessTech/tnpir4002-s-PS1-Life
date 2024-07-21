# General Feedback

## Good
- Built in analytics
- Fairly verbose

## Bad
- All duplicates treated as equal, no control over location prioritization
  - In my testing, I had two duplicate folders with the same contents
  - I now have random files pulled from each directory which is...not great
- Many of the original variable names were unhelpful

## Ugly
- No error handling
- Several anti-patterns, including using ALLCAPS function names
- Functions assumed data would be available in the session rather than requiring data to be passed in.

---

## Things I did/added

- I created a custom messaging service. It allows you to tee out to logging if you want. I tried to make sure all formatting you did copied over correctly.
- I enhanced your script variables by elevating them to "script", rather than simple local variables.
- I moved functions to a specific file.
