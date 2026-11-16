# Grey.D'Studio Sales Pipeline

Team app for leads, projects, design deliverables and dashboards.

- Frontend: this repo, served by GitHub Pages.
- Database and logins: Supabase. Data is protected by row-level security, so nothing can be read without a login linked to the team.
- This repo holds code only. Never commit client data, exports or Supabase secret keys here.

## Setup (once)
1. Supabase, SQL Editor: run `supabase-setup.sql`.
2. Supabase, Authentication, Sign In / Providers, Email: turn off **Confirm email**.
3. GitHub, Settings, Pages: Branch `main`, folder `/ (root)`.
4. Open the site, First-time setup, create the owner account, then run the SQL it shows.
5. In the claude.ai app: Team, Export data. In this app: Team, Import data.
6. Team: set a User ID and password for each member.
