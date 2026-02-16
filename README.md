# Academic Personal Website (GitHub Pages + Jekyll)

A simple, maintainable personal site for recreational drugs research.
Designed so non-technical edits happen mostly in Markdown and YAML data files.

## Edit These Files (Most Important)

- `_data/profile.yml`
  - Name, title, email, LinkedIn, short bio, long bio, profile photo path.
- `_data/publications.yml`
  - Publications grouped by year, plus blog links.
- `faq.md`
  - Parent FAQ text.
- `assets/cv/cv.pdf`
  - Your current CV PDF used on the About page.
- `assets/img/`
  - Profile and other page images.

## 1) Create the GitHub Repository

1. Create a new GitHub repository.
2. Copy these files into the repository root.
3. Commit and push.

If this is your personal site repo, name it exactly:

- `yourusername.github.io`

If this is a project site repo, any repo name is fine (for example `research-site`).

## 2) Enable GitHub Pages

1. Open your repository on GitHub.
2. Go to **Settings** -> **Pages**.
3. Under **Build and deployment**:
   - Source: **Deploy from a branch**
   - Branch: **main**
   - Folder: **/ (root)**
4. Save.

GitHub Pages usually publishes within a minute or two.

## 3) Configure `url` and `baseurl` in `_config.yml`

Edit `_config.yml`:

- `url`: set to your domain root, for example `https://yourusername.github.io`
- `baseurl`:
  - User site (`yourusername.github.io`): `""`
  - Project site (`yourusername.github.io/repo-name`): `"/repo-name"`

The templates already use `relative_url`, so links and CSS work for both cases.

## 4) Edit Site Content

### Home page

- File: `index.md`
- Most displayed text is pulled from `_data/profile.yml`

### About page

- File: `about.md`
- Long bio and CV link come from `_data/profile.yml`

### Publications and Blog

- File: `works.md`
- Data source: `_data/publications.yml`

### Parent FAQ

- File: `faq.md`

## 5) Change Photos

### Profile photo

1. Upload your photo into `assets/img/`.
2. Update `profile_photo` in `_data/profile.yml`.

Example:

```yml
profile_photo: "/assets/img/my-photo.jpg"
profile_photo_alt: "Portrait of Hayley K Murray"
```

## Optional: Local Preview (Beginner-Friendly)

If you want to preview before pushing:

1. Install Ruby and Jekyll.
2. In this folder, run:

```bash
bundle exec jekyll serve
```

3. Open the local URL printed in the terminal (usually `http://127.0.0.1:4000`).

If local setup feels too technical, skip this and rely on GitHub Pages preview after push.

## Notes

- No custom plugins are required.
- Navigation is shared across pages via includes.
- Main content is intentionally centralized in Markdown and `_data/*.yml` files.
