
# build deckset
mdslides compile s3-practical-guide.yaml src/ tmp/ --chapter-title=img --glossary=glossary.yaml
mdslides build deckset s3-practical-guide.yaml tmp/ S3-Praxisleitfaden.md --template=templates/deckset-template.md  --glossary=glossary.yaml --glossary-items=16
# append pattern-index
python pattern_index_deckset.py S3-Praxisleitfaden.md pattern-index.yaml

# build reveal.js
mdslides compile s3-practical-guide.yaml src/ tmp/ --chapter-title=text --glossary=glossary.yaml
mdslides build revealjs s3-practical-guide.yaml  tmp/ reveal.js/S3-Praxisleitfaden.html --template=templates/revealjs-template.html  --glossary=glossary.yaml  --glossary-items=8

# build wordpress output
mdslides compile s3-practical-guide.yaml src/ tmp/ --chapter-title=none --glossary=glossary.yaml
mdslides build wordpress s3-practical-guide.yaml tmp/ web-out/ --footer=templates/wordpress-footer.md  --glossary=glossary.yaml