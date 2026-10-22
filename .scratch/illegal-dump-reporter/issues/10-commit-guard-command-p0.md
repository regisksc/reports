# 10: Commit guard command context

Status: resolved
Priority: P0
Blocked by: none

## Acceptance

- Every single, batched, and appeal review receives the exact intercepted Git command so dangerous-operation validation has the evidence it requires.
- Non-executing file edits containing command examples must not be mistaken for actual command execution. Actual shell operations remain guarded.
- Required validators, restricted reviewer tools, fail-closed behavior, and genuine policy NACKs stay intact.
- Isolate and commit only this P0 delta; preserve pre-existing dirty changes in the machine repository.
- Red regression, fresh full tests, 100% measured coverage, clean typecheck/lint/build, and independent review are required before completion.

## Comments

User explicitly requested this as P0 before returning to app completion. Repository: /Users/regiskian/.agents. Task branch: fix/ketchup-command-context. Isolated worktree: /tmp/ketchup-command-context-worktree. Baseline: 68aaf0d.

Command propagation and non-executing patch regressions reproduced and fixed. Commits on fix/ketchup-command-context: 6b9db797 (hermetic Git-root fixture), 6d0e224b (exact command evidence), 6df43c89 (patch classification). Parent fresh full runs: isolated 298/298, installed active checkout 453/453; both had 100% statements, branches, functions, and lines. Typecheck, scoped lint, and build passed. Standards and Spec reviews had zero actionable findings. Exact committed classification delta passed all 19 enabled validators; allowed=true, with no appeal override. These are recorded observed results; the temporary evidence artifact is no longer available.

The installed bundle is rebuilt. A native patch containing a literal commit example was accepted without executing it. Actual shell operations and protected paths remain guarded. Prior dirty machine-repository changes were preserved.

The clean isolated worktree was removed after verification. The fix branch and
three commits are retained. The old temporary validator evidence and coverage
artifacts were lost when the checkout disappeared, so this ticket makes no
claim that those artifacts remain available.

The reports bootstrap review then saw the command correctly. Its substantive
atomicity and type-organization findings were resolved through scoped behavior
commits and co-location with the actual implementation.
