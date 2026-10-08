# Notes for Claude Code

- Talk to the user in Turkish.
- Read `PLAN.md` first and keep it up to date. It is the only memory shared with the Claude Code session on the user's Windows PC, which works on [UpLa for Windows](https://github.com/Agnostique/UpLa).
- The repository is public. Never commit `Config/Secrets.xcconfig`, API keys (including the shared guest key), certificates, passwords or delete links. Check `git diff --cached` before every commit.
- No real uploads, sign-ins or other POST requests to upla.com.tr without the user's explicit approval. Use the `URLProtocol` stubs and fixtures instead.
- Server changes (upla.com.tr pages, routes) are made from the Windows session and need the user's approval.
- Git identity: `Agnostique <20846034+Agnostique@users.noreply.github.com>`.
- For upla.com.tr behaviour (limits, error codes, sign-in), the Windows app is the reference: `ShareX.UploadersLib/Upla/` in https://github.com/Agnostique/UpLa.
