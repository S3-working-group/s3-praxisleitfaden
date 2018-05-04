
CONFIG=templates/config.yaml
GLOSSARY=content/glossary.yaml
PATTERNINDEX=content/pattern-index.yaml
SOURCE=content/src
TMPFOLDER=tmp

include make-conf


define update-make-conf
# update the make conf file from translations
mdslides template templates/make-conf make-conf content/localization.po project.yaml
endef

define build-index-db
mdslides build-index-db $(CONFIG) $(PATTERNINDEX)
endef

define prepare-ebook
# prepare and copy templates
mdslides template templates/ebook/ebook--master.md tmp/ebook/ebook--master.md content/localization.po project.yaml
mdslides template templates/ebook/ebook-epub--master.md tmp/ebook/ebook-epub--master.md content/localization.po project.yaml
mdslides template templates/ebook/ebook-proof.tex tmp/ebook/ebook-proof.tex content/localization.po project.yaml
mdslides template templates/ebook/ebook-style.sty tmp/ebook/ebook-style.sty content/localization.po project.yaml
# render intro, chapters and appendix to separate md files
mdslides build ebook $(CONFIG) $(SOURCE) tmp/ebook/ --glossary=$(GLOSSARY) --index=$(PATTERNINDEX) --section-prefix="$(SECTIONPREFIX)"
# transclude all to one file 
cd tmp/ebook; multimarkdown --to=mmd --output=tmp-ebook-compiled.md ebook--master.md
cd tmp/ebook; multimarkdown --to=mmd --output=tmp-ebook-epub-compiled.md ebook-epub--master.md
endef


deckset:
	$(update-make-conf)

ifeq "$(BUILD_INDEX)" "YES"
	# build index database (only for the English repo!!)
	$(build-index-db)
endif

	# build deckset presentation and add pattern index
	mdslides compile $(CONFIG) $(SOURCE) $(TMPFOLDER) --chapter-title=img --glossary=$(GLOSSARY) --section-prefix="$(SECTIONPREFIX)"
	
	mdslides template templates/deckset-template.md tmp/deckset-template.md content/localization.po project.yaml
	mdslides build deckset $(CONFIG) $(TMPFOLDER) $(TARGETFILE).md --template=tmp/deckset-template.md  --glossary=$(GLOSSARY) --glossary-items=16
	# append pattern-index
	mdslides deckset-index $(PATTERNINDEX) $(TARGETFILE).md

revealjs:
	$(update-make-conf)

	mdslides template templates/revealjs-template.html tmp/revealjs-template.html content/localization.po project.yaml

	mdslides compile $(CONFIG) $(SOURCE) $(TMPFOLDER) --chapter-title=text --glossary=$(GLOSSARY) --section-prefix="$(SECTIONPREFIX)"
	mdslides build revealjs $(CONFIG) $(TMPFOLDER) docs/slides.html --template=tmp/revealjs-template.html  --glossary=$(GLOSSARY) --glossary-items=8

site:
	# build jekyll site
	$(update-make-conf)

	# prepare templates
	mdslides template templates/docs/_layouts/default.html docs/_layouts/default.html content/localization.po project.yaml
	mdslides template templates/docs/_config.yml docs/_config.yml content/localization.po project.yaml
	mdslides template templates/docs/CNAME docs/CNAME content/localization.po project.yaml
	# cp content/website/_includes/footer.html docs/_includes/footer.html
	mdslides template content/website/_includes/footer.html docs/_includes/footer.html content/localization.po project.yaml
	cp content/website/_includes/header.html docs/_includes/header.html

ifeq "$(BUILD_INDEX)" "YES"
	# build index database (only for the English repo!!)
	$(build-index-db)
endif

	mdslides build jekyll $(CONFIG) $(SOURCE) docs/ --glossary=$(GLOSSARY) --template=content/website/_templates/index.md --index=$(PATTERNINDEX)
	cd docs;jekyll build

wordpress:
	# join each pattern group into one md file to be used in wordpress
	$(update-make-conf)
ifeq ("$(wildcard $(TMPFOLDER)/web-out)","")
	mkdir $(TMPFOLDER)/web-out
endif 


	mdslides compile $(CONFIG) $(SOURCE) $(TMPFOLDER) --chapter-title=none --glossary=$(GLOSSARY) --section-prefix="$(SECTIONPREFIX)"
	mdslides build wordpress $(CONFIG) $(TMPFOLDER) $(TMPFOLDER)/web-out/ --footer=templates/wordpress-footer.md  --glossary=$(GLOSSARY)

epub:
	# render an ebook as epub
	$(update-make-conf)
	$(prepare-ebook)

	cd tmp/ebook; pandoc tmp-ebook-epub-compiled.md -f markdown -t epub3 -s -o ../../$(TARGETFILE).epub

	# clean up
	cd tmp/ebook; rm tmp-*

e-book:
	# render an ebook as pdf
	$(update-make-conf)
	$(prepare-ebook)

	cd tmp/ebook; multimarkdown --to=latex --output=tmp-ebook-compiled.tex tmp-ebook-compiled.md
	cd tmp/ebook; latexmk -pdf ebook-proof.tex 
	cd tmp/ebook; mv ebook-proof.pdf ../../$(TARGETFILE)-ebook.pdf
	
	# clean up
	cd tmp/ebook; latexmk -C
	cd tmp/ebook; rm tmp-*

html:
	$(update-make-conf)
	
	# render intro, chapters and appendix to separate md files
	mdslides build ebook $(CONFIG) $(SOURCE) ebook/ --glossary=$(GLOSSARY) --index=$(PATTERNINDEX)
	# transclude all to one file 
	cd ebook; multimarkdown --to=mmd --output=../docs/all.md single-page--master.md
	# clean up
	cd ebook; rm tmp-*

update:
	$(update-make-conf)

clean:
	# clean all generated content
	-rm -r docs/img
	-rm -r docs/_site
	-rm docs/*.md
	-rm -r $(TMPFOLDER)

setup:
	# prepare temp folders and jekyll site
	$(update-make-conf)
	# prepare temp folders
	echo "this might produce error output if folders already exist"
	-mkdir -p $(TMPFOLDER)/ebook
	-mkdir -p $(TMPFOLDER)/web-out
	-mkdir docs/_site
ifeq ("$(wildcard $(TMPFOLDER)/ebook/img)","")
	cd $(TMPFOLDER)/ebook; ln -s ../../img
endif 
	# clean up and copy images do to docs folder
ifneq ("$(wildcard docs/img)","")
	rm -r docs/img
endif
	cp -r img docs/img

