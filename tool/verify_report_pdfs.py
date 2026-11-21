"""Verify artifacts from test/report_pdf_design_test.dart; optionally render QA pages.

Usage: python tool/verify_report_pdfs.py [--render]
Requires pypdf; rendering additionally requires pdfplumber and its PDFium backend.
"""
import argparse
import json
import re
from pathlib import Path
from pypdf import PdfReader


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--render', action='store_true')
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    directory = root / 'build/pdf_review'
    errors = []
    documents = []
    for language in ('en', 'sw'):
        expected = [f'catalog-{i:02}' for i in range(79)] + [
            'customers', 'expenses', 'debt-statement', 'analytical',
            'empty', 'long-cell', 'large-wide', 'filtered',
        ]
        if language == 'sw':
            expected.append('names-preserved')
        for name in expected:
            path = directory / language / f'{name}.pdf'
            if not path.exists():
                errors.append(f'Missing {language}/{name}')
                continue
            reader = PdfReader(path)
            texts = [page.extract_text() or '' for page in reader.pages]
            text = '\n'.join(texts)
            compact = re.sub(r'\s+', '', text)

            def require(token):
                if re.sub(r'\s+', '', token) not in compact:
                    errors.append(f'{language}/{name}: missing {token!r}')

            require('GreenLeaf Shop')
            require('Neema Msimamizi')
            require('Ukurasa' if language == 'sw' else 'Page')
            for i, page_text in enumerate(texts, 1):
                footer = f'Ukurasa {i} kati ya {len(texts)}' if language == 'sw' else f'Page {i} of {len(texts)}'
                if re.sub(r'\s+', '', footer) not in re.sub(r'\s+', '', page_text):
                    errors.append(f'{language}/{name}: incorrect footer on page {i}')
            if '[Weka Jina la Duka]' in text or '[Kumb. Na.]' in text:
                errors.append(f'{language}/{name}: copied template placeholders')
            if name == 'large-wide':
                found = re.findall(r'ROW-\d{4}', compact)
                if len(found) != 1000 or len(set(found)) != 1000:
                    errors.append(f'{language}/{name}: expected exactly 1000 unique data rows')
                if reader.pages[0].mediabox.width <= reader.pages[0].mediabox.height:
                    errors.append(f'{language}/{name}: expected landscape')
            if name == 'long-cell':
                for token in ('END_LONG_CELL', 'LAST_REPORT_ROW', '-1,234.50', '9,876.54'):
                    require(token)
                if compact.count('-1,234.50') != 1:
                    errors.append(f'{language}/{name}: duplicated financial value')
                if len(texts) < 2:
                    errors.append(f'{language}/{name}: continuation case did not span pages')
            if name == 'customers':
                for token in ('Amina Trading', '7,400.00', '1,500.00'):
                    require(token)
            if name == 'expenses':
                for token in ('Delivery fuel', '2,000.00', '100.00', '2,100.00'):
                    require(token)
                if language == 'sw':
                    require('Imewasilishwa')
            if name == 'debt-statement':
                for token in ('Amina Trading', '2,000.00', '500.00', '1,500.00'):
                    require(token)
            if name == 'filtered':
                require('FILTERED_ROW')
                require('42.25')
                # One occurrence in the search metadata, one in the actual table.
                if compact.count('FILTERED_ROW') != 2:
                    errors.append(f'{language}/{name}: row was duplicated')
            if name == 'analytical':
                for number in range(1, 9):
                    require(f'{number}.')
            if name == 'names-preserved':
                require('Net sales')
                require('Gross profit')
            documents.append({'file': str(path.relative_to(root)), 'pages': len(texts)})
    result = {'documents': documents, 'errors': errors}
    (root / 'build/pdf-review-audit.json').write_text(json.dumps(result, indent=2), encoding='utf8')
    print(f'{len(documents)} PDFs, {sum(d["pages"] for d in documents)} pages; {len(errors)} errors.', flush=True)
    for error in errors:
        print(error)
    if args.render:
        render(directory)
    raise SystemExit(bool(errors))


def render(directory):
    import pdfplumber
    output = directory / 'images'
    output.mkdir(exist_ok=True)
    samples = [('sw/catalog-31.pdf', 'inventory'), ('sw/catalog-32.pdf', 'financial'),
               ('sw/expenses.pdf', 'expenses'), ('sw/debt-statement.pdf', 'statement'),
               ('en/analytical.pdf', 'analysis'), ('sw/long-cell.pdf', 'long'),
               ('en/large-wide.pdf', 'wide')]
    count = 0
    for filename, label in samples:
        with pdfplumber.open(directory / filename) as pdf:
            for i in sorted({0, len(pdf.pages) // 2, len(pdf.pages) - 1}):
                page = pdf.pages[i]
                page.to_image(resolution=110).save(output / f'{label}-{i + 1}.png')
                count += 1
    print(f'Rendered {count} representative pages in {output}.', flush=True)


if __name__ == '__main__':
    main()
