
include make-conf
CONFIG=config.yaml
GLOSSARY=glossary.yaml
TMPFOLDER=tmp/
PATTERNINDEX = pattern-index.yaml

deckset:
	mdslides compile $(CONFIG) src/ $(TMPFOLDER) --chapter-title=img --glossary=$(GLOSSARY) --section-prefix=$(SECTIONPREFIX)
	mdslides build deckset $(CONFIG) $(TMPFOLDER) $(TARGETFILE).md --template=templates/deckset-template.md  --glossary=$(GLOSSARY) --glossary-items=16
	# append pattern-index
	mdslides deckset-index $(PATTERNINDEX) $(TARGETFILE).md

revealjs:
	mdslides compile $(CONFIG) src/ $(TMPFOLDER) --chapter-title=text --glossary=$(GLOSSARY) --section-prefix=$(SECTIONPREFIX)
	mdslides build revealjs $(CONFIG) $(TMPFOLDER) reveal.js/$(TARGETFILE).html --template=templates/revealjs-template.html  --glossary=$(GLOSSARY) --glossary-items=8

site:
	mdslides build jekyll $(CONFIG) src docs/ --glossary=$(GLOSSARY) --template=docs/_templates/index.md --index=$(PATTERNINDEX)
	cd docs; jekyll build
