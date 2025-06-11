# AI Developer Guidelines

> Essential practices for AI developers working on the Athena project

## 🎯 Core Principles

### 1. Keep Git Clean
- **Always keep git clean when working on something new**, even at the risk of having excessive git commits
- Commit frequently - every logical change deserves a commit
- Never leave uncommitted work when switching tasks
- Push after every commit for real-time collaboration

### 2. Address Warnings Immediately
- **Fix all compilation warnings before proceeding**
- Warnings often indicate future bugs
- Clean code compiles without warnings
- Use `mix compile --warnings-as-errors` to enforce this

### 3. User Interaction
- **Use the `say` command when responding to the user and expecting an answer**
- Makes it clear when input is needed
- Improves user experience with audio feedback
- Example: `say "Which feature should I implement first?"`

### 4. Debugging Strategy
- **When something isn't working, look for a working example and compare**
- Don't assume the problem is due to something complex
- Check the obvious things first:
  - Is the syntax correct?
  - Are all modules imported/aliased?
  - Is there a working example in the codebase?
- Compare line-by-line with working code before diving deep

### 5. Efficient Searching
- **Searching is expensive - prefer looking in places you know**
- Avoid blanket searches like `find . -name "*"`
- Use targeted searches:
  - Know the directory structure
  - Search specific directories first
  - Use `EXISTING_TOOLS_AND_SYSTEMS.md` as a map
- Examples:
  - ❌ `grep -r "function" .` (searches everything)
  - ✅ `grep "function" lib/ash_chat/ai/*.ex` (targeted)

## 📋 Quick Checklist

Before starting any task:
- [ ] Git status clean?
- [ ] No compilation warnings?
- [ ] Know where to look for examples?
- [ ] Have a specific search strategy?

When stuck:
- [ ] Found a working example to compare?
- [ ] Checked the obvious issues first?
- [ ] Used `say` to ask for clarification?
- [ ] Committed progress so far?

## 🔧 Practical Tips

1. **Use aliases and bookmarks**
   ```bash
   alias clean='mix compile --warnings-as-errors && git status'
   alias save='git add -A && git commit -m'
   ```

2. **Know your key files**
   - `/lib/ash_chat/` - Main application code
   - `/system/` - External integrations
   - `/docs/` - Documentation and guidelines
   - `EXISTING_TOOLS_AND_SYSTEMS.md` - Tool inventory

3. **Compare before assuming**
   - Working: `alias AshChat.Resources.{Room, User}`
   - Broken: `alias AshChat.Resources.Room, User`
   - The difference is subtle but critical!

4. **Commit message pattern**
   ```
   <verb> <what changed>
   
   - <why it was needed>
   - <what it enables>
   ```

## 🚨 Common Pitfalls to Avoid

1. **Accumulating uncommitted changes** - Makes debugging harder
2. **Ignoring warnings** - They compound into errors
3. **Broad searches** - Waste time and context tokens
4. **Assuming complex causes** - Usually it's a typo or missing import
5. **Silent failures** - Use `say` to communicate status

## 📝 File Formatting Standards

### Always End Files with a Newline
- All text files should end with a newline character
- This includes: `.md`, `.sh`, `.ex`, `.exs`, `.js`, `.yml`, `.toml`, etc.
- Why: Unix convention, prevents "No newline at end of file" in diffs
- Git and many tools expect this standard

### Checking and Fixing
```bash
# Check if file ends with newline
tail -c 1 file.md | wc -l  # Returns 0 if no newline

# Add newline if missing
echo "" >> file.md

# Fix multiple files
for file in *.md; do
  if [ $(tail -c 1 "$file" | wc -l) -eq 0 ]; then
    echo "" >> "$file"
  fi
done
```

---

*Remember: Clean code, clean git, clear communication*
