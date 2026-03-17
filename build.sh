#!/bin/bash
set -e

SRC="src"
OUT="output"
THEME="theme/template.html"

mkdir -p "$OUT"
for subj in dsa os networks database architecture toc compiler discrete cpp; do
    mkdir -p "$OUT/$subj"
done

python3 - <<'PYEOF'
import os, subprocess, json, re

SRC = "src"
OUT = "output"
THEME = "theme/template.html"

SUBJECTS = {
    "dsa": "Data Structures &amp; Algorithms",
    "os": "Operating Systems",
    "networks": "Computer Networks",
    "database": "Database Systems",
    "architecture": "Computer Architecture",
    "toc": "Theory of Computation",
    "compiler": "Compiler Design",
    "discrete": "Discrete Mathematics",
    "cpp": "C++",
}

ORDER = ["dsa","os","networks","database","architecture","toc","compiler","discrete","cpp"]

with open(THEME) as f:
    TEMPLATE = f.read()

def get_title(mdfile):
    with open(mdfile) as f:
        for line in f:
            m = re.match(r'^#\s+(.+)', line)
            if m:
                return m.group(1)
    return os.path.basename(mdfile).replace(".md","")

def get_pages(subj):
    path = os.path.join(SRC, subj)
    if not os.path.isdir(path):
        return []
    pages = []
    for fname in sorted(os.listdir(path)):
        if fname.endswith(".md"):
            slug = fname.replace(".md","")
            title = get_title(os.path.join(path, fname))
            pages.append((slug, title))
    return pages

def build_nav(current_subj="", current_slug=""):
    nav = ""
    for subj in ORDER:
        display = SUBJECTS.get(subj, subj)
        pages = get_pages(subj)
        if not pages:
            continue
        is_active = subj == current_subj
        active_class = " active" if is_active else ""
        nav += f'<div class="nav-subject{active_class}">'
        if is_active:
            nav += f'<div class="nav-subject-name">{display}</div>'
        else:
            nav += f'<div class="nav-subject-name" onclick="toggleSubject(this)">{display}</div>'
        collapsed = "" if is_active else " collapsed"
        nav += f'<div class="nav-pages{collapsed}">'
        for slug, title in pages:
            current = " current" if (subj == current_subj and slug == current_slug) else ""
            nav += f'<a href="/{subj}/{slug}.html" class="nav-page{current}">{title}</a>'
        nav += '</div></div>'
    return nav

def render(template, nav, content, title, subject, breadcrumb):
    return (template
        .replace("NAV_PLACEHOLDER", nav)
        .replace("CONTENT_PLACEHOLDER", content)
        .replace("TITLE_PLACEHOLDER", title)
        .replace("SUBJECT_PLACEHOLDER", subject)
        .replace("BREADCRUMB_PLACEHOLDER", breadcrumb))

def md_to_html(mdfile):
    result = subprocess.run(
        ["pandoc", mdfile, "-f", "markdown", "-t", "html", "--highlight-style=zenburn"],
        capture_output=True, text=True
    )
    return result.stdout

# ── search index ──
entries = []
for subj in ORDER:
    path = os.path.join(SRC, subj)
    if not os.path.isdir(path):
        continue
    for fname in sorted(os.listdir(path)):
        if not fname.endswith(".md"):
            continue
        fpath = os.path.join(path, fname)
        with open(fpath) as f:
            content = f.read()
        title_match = re.search(r'^#\s+(.+)', content, re.MULTILINE)
        title = title_match.group(1) if title_match else fname.replace(".md","")
        body = re.sub(r'[#*`\[\]()>_~]', '', content)
        body = re.sub(r'\s+', ' ', body).strip()[:600]
        slug = fname.replace(".md","")
        entries.append({"title": title, "subject": subj, "slug": slug,
                        "url": f"/{subj}/{slug}.html", "body": body})

with open(os.path.join(OUT, "search-index.json"), "w") as f:
    json.dump(entries, f)
print(f"search index: {len(entries)} entries")

# ── homepage ──
cards = ""
for subj in ORDER:
    display = SUBJECTS.get(subj, subj)
    pages = get_pages(subj)
    if not pages:
        continue
    first_slug = pages[0][0]
    count = len(pages)
    cards += f'<a href="/{subj}/{first_slug}.html" class="subject-card"><div class="card-name">{display}</div><div class="card-count">{count} {"page" if count == 1 else "pages"}</div></a>'

home_content = f'''<div class="homepage"><div class="home-header"><div class="home-eyebrow">// knowledge base</div><h1 class="home-title">Sophia</h1><p class="home-sub">core computer science — notes, concepts, and clarity.</p></div><div class="subject-grid">{cards}</div></div>'''

html = render(TEMPLATE, build_nav(), home_content, "Sophia", "", '<a href="/">home</a>')
with open(os.path.join(OUT, "index.html"), "w") as f:
    f.write(html)
print("built: index.html")

# ── pages ──
for subj in ORDER:
    display = SUBJECTS.get(subj, subj)
    pages = get_pages(subj)
    if not pages:
        continue
    for slug, title in pages:
        mdfile = os.path.join(SRC, subj, slug + ".md")
        content = md_to_html(mdfile)
        nav = build_nav(subj, slug)
        breadcrumb = f'<a href="/">home</a> / <a href="/{subj}/{pages[0][0]}.html">{display}</a> / <span>{title}</span>'
        html = render(TEMPLATE, nav, content, title, display, breadcrumb)
        outfile = os.path.join(OUT, subj, slug + ".html")
        with open(outfile, "w") as f:
            f.write(html)
        print(f"built: {subj}/{slug}.html")

print("done.")
PYEOF
