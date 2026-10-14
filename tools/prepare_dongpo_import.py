"""Validate the editorial catalog and generate a transactional Supabase seed.

Run from the repository root: python tools/prepare_dongpo_import.py
This prepares SQL only; it never claims to have written to the database.
"""
import collections
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / 'assets/data/dongpo_sites.json'
OUTPUT = ROOT / 'supabase/seed_dongpo_sites.sql'
THEMES = {'水利治绩', '交游酬唱', '诗词题咏', '民生善政', '自然山水'}
REQUIRED = (
    'name_modern', 'name_ancient', 'address', 'period', 'historical_event',
    'related_literature', 'literature_source', 'research_notes',
)


def validate(rows):
    if len(rows) != 37 or {row['id'] for row in rows} != set(range(1, 38)):
        raise ValueError('Expected exactly 37 unique appendix entries numbered 1–37')
    if collections.Counter(row['heritage_grade'] for row in rows) != {
        '确证': 30, '疑似': 2, '已佚': 5,
    }:
        raise ValueError('Evidence levels differ from appendix B (30/2/5)')
    if sum(row['is_core_site'] for row in rows) != 10:
        raise ValueError('Exactly ten core sites must be selected')
    for row in rows:
        if not all(row.get(field, '').strip() for field in REQUIRED):
            raise ValueError(f"Incomplete historical fields at entry {row['id']}")
        if not row['themes'] or not set(row['themes']).issubset(THEMES):
            raise ValueError(f"Invalid themes at entry {row['id']}")
        coords = row['coordinates']
        if coords and (len(coords) != 2 or not -180 <= coords[0] <= 180
                       or not -90 <= coords[1] <= 90):
            raise ValueError(f"Invalid coordinates at entry {row['id']}")
        if coords and row.get('coordinate_system') != 'GCJ-02':
            raise ValueError('Map coordinates must explicitly use GCJ-02')
        for photo in row['photos']:
            if not all(photo.get(key) for key in ('url', 'credit', 'source', 'license')):
                raise ValueError('Photos need a URL, photographer, source and license')


def main():
    rows = json.loads(DATA.read_text(encoding='utf-8'))
    validate(rows)
    columns = list(rows[0])
    names = ', '.join('"' + key + '"' for key in columns)
    assignments = ',\n  '.join(
        f'"{key}" = excluded."{key}"' for key in columns if key not in ('id', 'photos')
    )
    # jsonb_populate_recordset validates all types against the table schema.
    # A quoted JSON literal avoids collisions with dollar-quote delimiters.
    payload = json.dumps(rows, ensure_ascii=False).replace("'", "''")
    sql = f'''-- Generated from assets/data/dongpo_sites.json; run setup_dongpo_sites.sql first.
-- Existing field photos are preserved unless this import explicitly supplies photos.
begin;
insert into public.dongpo_sites ({names})
select {names}
from jsonb_populate_recordset(null::public.dongpo_sites, '{payload}'::jsonb)
on conflict (id) do update set
  {assignments},
  photos = case when jsonb_array_length(excluded.photos) > 0
    then excluded.photos else dongpo_sites.photos end;
commit;

-- Read this result to verify the cloud import.
select heritage_grade, count(*) from public.dongpo_sites group by heritage_grade;
select count(*) as total, count(*) filter (where is_core_site) as core_sites,
       count(*) filter (where cardinality(coordinates) = 2) as located_sites,
       count(*) filter (where jsonb_array_length(photos) > 0) as photographed_sites
from public.dongpo_sites;
'''
    OUTPUT.write_text(sql, encoding='utf-8')
    print(f'Validated 37 entries; wrote {OUTPUT.name}. Cloud import not yet executed.')


if __name__ == '__main__':
    main()
