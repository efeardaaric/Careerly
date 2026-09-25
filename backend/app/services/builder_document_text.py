"""Flatten ResumeDocument JSON to searchable plain text for ATS/scoring reuse."""

from __future__ import annotations

from typing import Any


def resume_document_to_plain_text(doc: dict[str, Any]) -> str:
    lines: list[str] = []
    personal = doc.get("personal") or {}
    name = str(personal.get("fullName") or "").strip()
    if name:
        lines.append(name)
    contact = [
        str(personal.get("email") or "").strip(),
        str(personal.get("phone") or "").strip(),
        str(personal.get("location") or "").strip(),
        str(personal.get("linkedin") or "").strip(),
        str(personal.get("website") or "").strip(),
    ]
    contact = [c for c in contact if c]
    if contact:
        lines.append(" · ".join(contact))
    lines.append("")

    visibility = doc.get("sectionVisibility") or {}
    order = doc.get("sectionOrder") or [
        "personal",
        "summary",
        "education",
        "experience",
        "projects",
        "skills",
        "languages",
        "certifications",
        "awards",
    ]

    labels = {
        "summary": "Summary",
        "education": "Education",
        "experience": "Experience",
        "projects": "Projects",
        "skills": "Skills",
        "languages": "Languages",
        "certifications": "Certifications",
        "awards": "Awards",
    }

    for key in order:
        if key == "personal":
            continue
        if visibility.get(key) is False:
            continue
        if key == "summary":
            summary = str(doc.get("summary") or "").strip()
            if summary:
                lines.append(labels["summary"])
                lines.append(summary)
                lines.append("")
        elif key == "education":
            items = doc.get("education") or []
            if not items:
                continue
            lines.append(labels["education"])
            for e in items:
                if not isinstance(e, dict):
                    continue
                head = " · ".join(
                    x
                    for x in [
                        str(e.get("school") or "").strip(),
                        str(e.get("degree") or "").strip(),
                        str(e.get("field") or "").strip(),
                    ]
                    if x
                )
                dates = " – ".join(
                    x
                    for x in [
                        str(e.get("startDate") or "").strip(),
                        str(e.get("endDate") or "").strip(),
                    ]
                    if x
                )
                if head:
                    lines.append(f"{head}{(' (' + dates + ')') if dates else ''}")
                details = str(e.get("details") or "").strip()
                if details:
                    lines.append(details)
            lines.append("")
        elif key == "experience":
            items = doc.get("experience") or []
            if not items:
                continue
            lines.append(labels["experience"])
            for e in items:
                if not isinstance(e, dict):
                    continue
                head = " · ".join(
                    x
                    for x in [
                        str(e.get("title") or "").strip(),
                        str(e.get("organization") or "").strip(),
                        str(e.get("location") or "").strip(),
                    ]
                    if x
                )
                dates = " – ".join(
                    x
                    for x in [
                        str(e.get("startDate") or "").strip(),
                        str(e.get("endDate") or "").strip(),
                    ]
                    if x
                )
                if head:
                    lines.append(f"{head}{(' (' + dates + ')') if dates else ''}")
                for b in e.get("bullets") or []:
                    lines.append(f"• {b}")
            lines.append("")
        elif key == "projects":
            items = doc.get("projects") or []
            if not items:
                continue
            lines.append(labels["projects"])
            for p in items:
                if not isinstance(p, dict):
                    continue
                name_p = str(p.get("name") or "").strip()
                if name_p:
                    lines.append(name_p)
                tech = p.get("tech") or []
                if tech:
                    lines.append("Tech: " + ", ".join(str(t) for t in tech))
                for b in p.get("bullets") or []:
                    lines.append(f"• {b}")
            lines.append("")
        elif key == "skills":
            groups = doc.get("skillGroups") or []
            if not groups:
                continue
            lines.append(labels["skills"])
            for g in groups:
                if not isinstance(g, dict):
                    continue
                label = str(g.get("label") or "").strip()
                skills = ", ".join(str(s) for s in (g.get("skills") or []))
                if label and skills:
                    lines.append(f"{label}: {skills}")
                elif skills:
                    lines.append(skills)
            lines.append("")
        elif key == "languages":
            items = doc.get("languages") or []
            if not items:
                continue
            lines.append(labels["languages"])
            for lang in items:
                if not isinstance(lang, dict):
                    continue
                n = str(lang.get("name") or "").strip()
                lvl = str(lang.get("level") or "").strip()
                if n:
                    lines.append(f"{n} ({lvl})" if lvl else n)
            lines.append("")
        elif key == "certifications":
            items = doc.get("certifications") or []
            if not items:
                continue
            lines.append(labels["certifications"])
            for c in items:
                if not isinstance(c, dict):
                    continue
                lines.append(
                    " · ".join(
                        x
                        for x in [
                            str(c.get("name") or "").strip(),
                            str(c.get("issuer") or "").strip(),
                            str(c.get("date") or "").strip(),
                        ]
                        if x
                    )
                )
            lines.append("")
        elif key == "awards":
            items = doc.get("awards") or []
            if not items:
                continue
            lines.append(labels["awards"])
            for a in items:
                if not isinstance(a, dict):
                    continue
                title = str(a.get("title") or "").strip()
                year = str(a.get("year") or "").strip()
                if title:
                    lines.append(f"{title}{(' · ' + year) if year else ''}")
            lines.append("")

    for custom in doc.get("customSections") or []:
        if not isinstance(custom, dict):
            continue
        title = str(custom.get("title") or "").strip() or "Custom"
        lines.append(title)
        for b in custom.get("bullets") or []:
            lines.append(f"• {b}")
        lines.append("")

    return "\n".join(lines).strip() + "\n"
