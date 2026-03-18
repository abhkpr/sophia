#!/usr/bin/env bash
set -euo pipefail

# ── config ──────────────────────────────────────────
SRC="src"
OUT="output"
THEME="theme/template.html"

# subject display names (order matters)
declare -a SUBJECT_ORDER=(
    "cpp"
    "dsa"
    "os"
    "networks"
    "database"
    "architecture"
    "toc"
    "compiler"
    "discrete"
)

declare -A SUBJECT_NAMES=(
    ["cpp"]="C++"
    ["dsa"]="Data Structures &amp; Algorithms"
    ["os"]="Operating Systems"
    ["networks"]="Computer Networks"
    ["database"]="Database Systems"
    ["architecture"]="Computer Architecture"
    ["toc"]="Theory of Computation"
    ["compiler"]="Compiler Design"
    ["discrete"]="Discrete Mathematics"
)

# ── install pandoc if missing ────────────────────────
install_pandoc() {
    if command -v pandoc &>/dev/null; then
        echo "pandoc: $(pandoc --version | head -1)"
        return
    fi
    echo "installing pandoc..."
    local VER="3.1.3"
    local URL="https://github.com/jgm/pandoc/releases/download/${VER}/pandoc-${VER}-linux-amd64.tar.gz"
    wget -q "$URL" -O /tmp/pandoc.tar.gz
    tar -xzf /tmp/pandoc.tar.gz -C /tmp
    export PATH="/tmp/pandoc-${VER}/bin:$PATH"
    echo "pandoc installed: $(pandoc --version | head -1)"
}

install_pandoc

# ── prepare output dirs ──────────────────────────────
mkdir -p "$OUT"
for subj in "${SUBJECT_ORDER[@]}"; do
    mkdir -p "$OUT/$subj"
done

# ── python builder ───────────────────────────────────
python3 - \
    "$SRC" "$OUT" "$THEME" \
    "${SUBJECT_ORDER[*]}" \
    "${!SUBJECT_NAMES[*]}" \
    << 'PYEOF'

import os, sys, re, json, subprocess, html

SRC    = sys.argv[1]
OUT    = sys.argv[2]
THEME  = sys.argv[3]

# rebuild subject order and names from env
ORDER_RAW = os.environ.get('ORDER', '')
NAMES_RAW = os.environ.get('NAMES', '')

# hardcoded here for reliability
ORDER = ["cpp","dsa","os","networks","database","architecture","toc","compiler","discrete"]

SUBJECTS = {
    "cpp":          "C++",
    "dsa":          "Data Structures &amp; Algorithms",
    "os":           "Operating Systems",
    "networks":     "Computer Networks",
    "database":     "Database Systems",
    "architecture": "Computer Architecture",
    "toc":          "Theory of Computation",
    "compiler":     "Compiler Design",
    "discrete":     "Discrete Mathematics",
}

# ── helpers ──────────────────────────────────────────

def clean_slug(fname):
    """01-fundamentals.md -> fundamentals"""
    slug = fname.replace(".md", "")
    return re.sub(r'^\d+[-_]', '', slug)

def get_title(path):
    """Extract first # heading from markdown, fallback to clean filename."""
    try:
        with open(path, encoding='utf-8') as f:
            for line in f:
                m = re.match(r'^#\s+(.+)', line)
                if m:
                    return m.group(1).strip()
    except Exception:
        pass
    return clean_slug(os.path.basename(path))

def get_pages(subj):
    """Return list of (clean_slug, raw_slug, title) sorted by filename."""
    path = os.path.join(SRC, subj)
    if not os.path.isdir(path):
        return []
    pages = []
    for fname in sorted(os.listdir(path)):
        if not fname.endswith(".md"):
            continue
        slug     = clean_slug(fname)
        raw_slug = fname.replace(".md", "")
        title    = get_title(os.path.join(path, fname))
        pages.append((slug, raw_slug, title))
    return pages

def md_to_html(mdfile):
    """Convert markdown to HTML using pandoc."""
    result = subprocess.run(
        ["pandoc", mdfile,
         "-f", "markdown+smart",
         "-t", "html",
         "--highlight-style=zenburn",
         "--no-highlight"],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        print(f"  pandoc warning: {result.stderr[:200]}", flush=True)
    return result.stdout

def build_nav(current_subj="", current_slug=""):
    """Build sidebar HTML."""
    nav = ""
    for subj in ORDER:
        display = SUBJECTS.get(subj, subj)
        pages   = get_pages(subj)
        if not pages:
            continue

        is_active = subj == current_subj
        is_open   = is_active  # keep active group open

        group_class = "nav-group"
        if is_active: group_class += " active"
        if is_open:   group_class += " open"

        # header
        if is_active:
            header_click = ""
        else:
            header_click = 'onclick="toggleGroup(this)"'

        nav += f'<div class="{group_class}">'
        nav += f'<div class="nav-group-header" {header_click}>'
        nav += f'<span class="nav-group-label">{display}</span>'
        nav += f'<span class="nav-group-arrow">▶</span>'
        nav += f'</div>'
        nav += f'<div class="nav-pages">'

        for slug, raw_slug, title in pages:
            page_class = "nav-page"
            if is_active and slug == current_slug:
                page_class += " active"
            nav += f'<a href="/{subj}/{slug}.html" class="{page_class}">{title}</a>'

        nav += '</div></div>'
    return nav

def render(nav, content, breadcrumb):
    """Substitute all placeholders in template."""
    with open(THEME, encoding='utf-8') as f:
        t = f.read()
    t = t.replace("NAV_PLACEHOLDER",        nav)
    t = t.replace("CONTENT_PLACEHOLDER",    content)
    t = t.replace("BREADCRUMB_PLACEHOLDER", breadcrumb)
    return t

def write(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

# ── search index ─────────────────────────────────────
print("building search index...", flush=True)
entries = []
for subj in ORDER:
    path = os.path.join(SRC, subj)
    if not os.path.isdir(path):
        continue
    for fname in sorted(os.listdir(path)):
        if not fname.endswith(".md"):
            continue
        fpath = os.path.join(path, fname)
        try:
            with open(fpath, encoding='utf-8') as f:
                raw = f.read()
        except Exception:
            continue
        title_m = re.search(r'^#\s+(.+)', raw, re.MULTILINE)
        title   = title_m.group(1).strip() if title_m else clean_slug(fname)
        body    = re.sub(r'```[\s\S]*?```', '', raw)   # strip code blocks
        body    = re.sub(r'[#*`\[\]()>_~|]', ' ', body)
        body    = re.sub(r'\s+', ' ', body).strip()[:500]
        slug    = clean_slug(fname)
        entries.append({
            "title":   title,
            "subject": subj,
            "slug":    slug,
            "url":     f"/{subj}/{slug}.html",
            "body":    body
        })

write(os.path.join(OUT, "search-index.json"), json.dumps(entries, ensure_ascii=False))
print(f"  {len(entries)} entries indexed", flush=True)

# ── homepage ──────────────────────────────────────────
print("building homepage...", flush=True)
cards = ""
for subj in ORDER:
    display = SUBJECTS.get(subj, subj)
    pages   = get_pages(subj)
    if not pages:
        continue
    first   = pages[0][0]
    count   = len(pages)
    label   = "page" if count == 1 else "pages"
    abbr    = subj.upper() if len(subj) <= 3 else subj[:2].upper()
    cards  += (
        f'<a href="/{subj}/{first}.html" class="subject-card">'
        f'<div class="card-icon">{abbr}</div>'
        f'<div class="card-name">{display}</div>'
        f'<div class="card-count">{count} {label}</div>'
        f'</a>'
    )

home_content = f'''<div class="homepage">
<div class="home-eyebrow">knowledge base</div>
<h1 class="home-title">So<em>phia</em></h1>
<p class="home-desc">Core computer science — structured notes, worked examples, and practice problems.</p>
<div class="home-divider"></div>
<div class="home-grid-label">subjects</div>
<div class="subject-grid">{cards}</div>
</div>'''

breadcrumb = '<a href="/">sophia</a>'
nav        = build_nav()
html_out   = render(nav, home_content, breadcrumb)
write(os.path.join(OUT, "index.html"), html_out)
print("  built: index.html", flush=True)

# ── subject pages ──────────────────────────────────────
for subj in ORDER:
    display = SUBJECTS.get(subj, subj)
    pages   = get_pages(subj)
    if not pages:
        continue

    for slug, raw_slug, title in pages:
        mdfile  = os.path.join(SRC, subj, raw_slug + ".md")
        if not os.path.exists(mdfile):
            print(f"  warning: {mdfile} not found, skipping", flush=True)
            continue

        content_body = md_to_html(mdfile)

        # wrap in article with meta
        content = (
            f'<div class="article">'
            f'<h1>{title}</h1>'
            f'<div class="page-meta">'
            f'<span class="tag">{display}</span>'
            f'</div>'
            f'{content_body}'
            f'</div>'
        )

        first_slug = pages[0][0]
        breadcrumb = (
            f'<a href="/">sophia</a>'
            f'<span class="breadcrumb-sep">/</span>'
            f'<a href="/{subj}/{first_slug}.html">{display}</a>'
            f'<span class="breadcrumb-sep">/</span>'
            f'<span class="breadcrumb-current">{title}</span>'
        )

        nav      = build_nav(subj, slug)
        html_out = render(nav, content, breadcrumb)
        outfile  = os.path.join(OUT, subj, slug + ".html")
        write(outfile, html_out)
        print(f"  built: {subj}/{slug}.html", flush=True)

print("done.", flush=True)
PYEOF
