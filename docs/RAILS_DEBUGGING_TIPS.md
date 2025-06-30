# Rails Debugging Tips for Claude Code Sessions

Quick reference for debugging Rails errors in the Soulsoup backend.

## 🧠 Using Thinking Triggers for Better Debugging

When you encounter a Rails error, start with these phrases to activate deeper analysis:
- **"Let me think deeply about this error"** - Triggers comprehensive understanding
- **"Let me think step-by-step through the problem"** - Ensures systematic debugging

Example:
```
"I see a TypeError. Let me think deeply about this error:
- The message says 'no implicit conversion of X into Hash'
- This usually means a method expected different parameter types
- Let me think step-by-step:
  1. What method is being called?
  2. What arguments is it receiving?
  3. What does the method signature actually expect?
  4. How should I fix the argument mismatch?"
```

## Common Rails Helper Errors

### TypeError: no implicit conversion of X into Hash

This usually means a method expects an options hash but got something else.

**Example from this session**:
```ruby
# WRONG - time_ago_in_words expects 1 time + optional hash
time_ago_in_words(start_time, end_time)  # end_time treated as options hash!

# CORRECT - use the right helper
distance_of_time_in_words(start_time, end_time)  # for duration between times
time_ago_in_words(start_time)                   # for "X ago" format
```

### Quick Helper Reference

| Helper | Purpose | Arguments |
|--------|---------|-----------|
| `time_ago_in_words` | "3 hours ago" format | `(time, options={})` |
| `distance_of_time_in_words` | Duration between times | `(from_time, to_time, options={})` |
| `time_tag` | HTML5 time element | `(time, content=nil, options={})` |

## Debugging Workflow

### 1. Check the Error Location
```bash
# The error shows file and line number
app/views/forge_sessions/_incarnation_card.html.erb:18
```

### 2. Test in Rails Console
```bash
cd soulsoup
rails console

# Test the problematic code
include ActionView::Helpers::DateHelper
time_ago_in_words(1.hour.ago, Time.now)  # See the error
distance_of_time_in_words(1.hour.ago, Time.now)  # Works!
```

### 3. Check Method Documentation
```bash
# In Rails console
ActionView::Helpers::DateHelper.instance_method(:time_ago_in_words).parameters
# => [[:req, :from_time], [:opt, :options]]

ActionView::Helpers::DateHelper.instance_method(:distance_of_time_in_words).parameters
# => [[:req, :from_time], [:opt, :to_time], [:opt, :options]]
```

### 4. Verify the Fix
- Make the change
- Refresh the browser (Rails auto-reloads views)
- Check for console errors
- Take screenshot of working page

## Rails Server Management

Use the Rails manager script for quick operations:
```bash
# From soulsoup directory
node scripts/rails_manager.js restart  # If changes aren't showing
node scripts/rails_manager.js status   # Check if server is running
```

## Common Pitfalls

1. **Assuming method signatures**: Always check what parameters a Rails helper expects
2. **Not refreshing after view changes**: Rails auto-reloads, but browser might cache
3. **Forgetting strong parameters**: When updating controllers
4. **Time zone issues**: Use `Time.zone.now` not `Time.now`

## Useful Rails Commands

```bash
# View routes
rails routes | grep forge

# Check model attributes
rails console
ForgeSession.column_names
Incarnation.first.attributes

# Test email templates
rails console
ApplicationMailer.test_email.deliver_now

# Clear cache if needed
rails tmp:clear
```

## Error Investigation Pattern

**Always start with: "Let me think step-by-step through this investigation"**

1. **Think deeply about the error**: What is it really telling me?
   - Error type hints at the problem category
   - Error message reveals the specific issue
   - Stack trace shows the execution path

2. **Step-by-step location analysis**: Where exactly did it break?
   - Rails errors show precise file and line numbers
   - Look at the surrounding code context
   - Understand what the code was trying to do

3. **Console testing with deliberate thinking**: 
   ```
   "Let me think step-by-step through testing this:
   1. First, I'll isolate the problematic code
   2. Then I'll test it in Rails console
   3. I'll verify my hypothesis about what's wrong
   4. Finally, I'll test the proposed fix"
   ```

4. **Documentation verification**: 
   - Check method signatures carefully
   - Verify parameter types and order
   - Look for similar issues in docs

5. **Minimal fix with deep consideration**:
   ```
   "Let me think deeply about this fix:
   - Does it address the root cause?
   - Will it handle edge cases?
   - Is it the simplest solution that works?"
   ```

6. **Systematic testing**: Include edge cases and verify completely

7. **Document with thinking process**: Record both the fix AND the reasoning

## The Power of Deep Thinking in Rails Debugging

**Without thinking triggers:**
```
"Got a TypeError. I'll try switching the parameters."
[Random guess-and-check approach]
```

**With thinking triggers:**
```
"Got a TypeError. Let me think deeply about this:
- TypeError usually means wrong data type passed to method
- Method expects Hash but got something else
- Let me think step-by-step through the method call:
  1. What method is being called? time_ago_in_words
  2. What arguments am I passing? (start_time, end_time)
  3. What does this method actually expect? Let me check docs...
  4. Ah! It expects (time, options_hash), not two times!
  5. I need distance_of_time_in_words for duration between two times"
```

The thinking approach turns debugging from guesswork into systematic problem-solving.

Remember: Rails errors are usually very descriptive. **Think deeply about what they're telling you!**