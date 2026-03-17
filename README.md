# Sophia

A personal knowledge base for core computer science subjects. Written in markdown, converted to HTML with pandoc.

## Structure

```
sophia/
├── build.sh          ← run this to build the site
├── src/
│   ├── dsa/          ← Data Structures & Algorithms
│   ├── os/           ← Operating Systems
│   ├── networks/     ← Computer Networks
│   ├── database/     ← Database Systems
│   ├── architecture/ ← Computer Architecture
│   ├── toc/          ← Theory of Computation
│   ├── compiler/     ← Compiler Design
│   ├── discrete/     ← Discrete Mathematics
│   └── cpp/          ← C++
├── theme/
│   └── template.html ← HTML template
└── output/           ← generated site (gitignored)
```

## Writing Notes

Add a markdown file to any subject folder:

```bash
nano src/dsa/linked-lists.md
```

Every file needs a top-level heading as the title:

```markdown
# Linked Lists

## Introduction
...
```

Then rebuild:

```bash
bash build.sh
```

## Building

Requirements: `pandoc`, `python3`

```bash
bash build.sh
```

Output goes to `output/`. Open `output/index.html` to preview.

## Deployment

Deployed on Cloudflare Pages:
- Build command: `bash build.sh`
- Output directory: `output`
