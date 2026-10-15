"""Prepare an optional, idempotent database sync for planning metadata.

The application can compose the two public catalogs before this SQL is applied.
Never updates source history, existing route associations, or user waypoints.
"""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def literal(value):
    return "'" + value.replace("'", "''") + "'"


def prepare():
    sites = json.loads((ROOT / 'assets/data/dongpo_sites.json').read_text(encoding='utf-8'))
    metadata = json.loads((ROOT / 'assets/data/dongpo_planning_metadata.json').read_text(encoding='utf-8'))
    assert len(sites) == len(metadata) == 37
    specs = {row['site_id']: row for row in metadata}
    sql = [
        '-- Optional planning metadata sync. Run with an authorized management connection.',
        '-- Standalone setup SQL; does not create a migration history entry.',
        'begin;',
        'alter table public."Location" add column if not exists heritage_grade text;',
        "alter table public.\"Location\" add column if not exists themes text[] not null default '{}';",
        'do $block$ begin',
        "  if not exists (select 1 from pg_constraint where conrelid = 'public.\"Location\"'::regclass and conname = 'location_heritage_grade_check') then",
        '    alter table public."Location" add constraint location_heritage_grade_check',
        "      check (heritage_grade is null or heritage_grade in ('确证', '疑似', '已佚'));",
        '  end if;',
        'end $block$;',
        'insert into public."Topic" (celebrity, name, description)',
        "select '苏轼', '东坡杭州行迹', '37 处杭州行迹，沿着治水、交游与诗文认识东坡。'",
        "where not exists (select 1 from public.\"Topic\" where celebrity = '苏轼' and name in ('东坡杭州行迹', '苏轼·杭州行迹', '苏轼杭州行迹'));",
    ]
    for site in sites:
        spec = specs[site['id']]
        aliases = spec['existing_names']
        if not aliases:
            continue
        tags = ['自然景观' if tag == '自然山水' else tag for tag in site['themes']]
        sql += [
            f"-- Source {site['id']}: {site['name_modern']}",
            'update public."Location" as location',
            f"set heritage_grade = {literal(site['heritage_grade'])},",
            '    themes = array(select distinct tag from unnest(',
            "      array_remove(coalesce(location.themes, '{}'::text[]), '自然山水') ||",
            '      array[' + ', '.join(map(literal, tags)) + ']::text[]',
            '    ) as labels(tag) order by tag)',
            'where name_modern in (' + ', '.join(map(literal, aliases)) + ');',
        ]
    sql += [
        '-- Read-back verification: the editorial source remains 37 records.',
        'select count(*) as dongpo_site_count from public.dongpo_sites;',
        'select heritage_grade, count(*) from public."Location"',
        'where heritage_grade is not null group by heritage_grade;',
        'commit;',
    ]
    output = ROOT / 'supabase/setup_dongpo_planning.sql'
    output.write_text('\n'.join(sql) + '\n', encoding='utf-8')
    print(f'Prepared {output.name}: {len(sites)} source records, {sum(len(row["existing_names"]) for row in metadata)} existing aliases')


if __name__ == '__main__':
    prepare()
