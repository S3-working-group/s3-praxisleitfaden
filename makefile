
CONFIG=content/structure.yaml
GLOSSARY=content/glossary.yaml
SOURCE=content/src
TMPFOLDER=tmp
TMPSUP = tmp/supporter-epub
EBOOK_TMP = tmp/ebook
DOCS_TMP = tmp/docs
LOC=content/localization.po
PRJ=config/project.yaml
MKTPL=mdslides template

# get language specific parameters
include config/make-conf

define update-make-conf
# update the make conf file from translations
$(MKTPL) templates/make-conf config/make-conf $(LOC) $(PRJ)
endef

site:
	# build jekyll site
	$(update-make-conf)

	# prepare templates
	$(MKTPL) templates/website/_layouts/default.html docs/_layouts/default.html $(LOC) $(PRJ)
	$(MKTPL) templates/website/_layouts/plain.html docs/_layouts/plain.html $(LOC) $(PRJ)
	$(MKTPL) templates/website/_config.yml docs/_config.yml $(LOC) $(PRJ)
	$(MKTPL) templates/website/CNAME docs/CNAME $(LOC) $(PRJ)
	$(MKTPL) content/website/_includes/footer.html docs/_includes/footer.html $(LOC) $(PRJ)
	cp templates/website/map.md docs/map.md
	$(MKTPL) templates/website/pattern-map.html docs/_includes/pattern-map.html $(LOC) $(PRJ)
	cp content/website/_includes/header.html docs/_includes/header.html
	cp content/website/_templates/404.md docs/404.md

	mdslides build jekyll $(CONFIG) $(SOURCE) docs/ --glossary=$(GLOSSARY) --template=content/website/_templates/index.md --section-index-template=content/website/_templates/pattern-index.md --introduction-template=content/website/_templates/introduction.md

	# build the single page version
	$(MKTPL) templates/single-page--master.md $(EBOOK_TMP)/single-page--master.md $(LOC) $(PRJ)
	# render intro, chapters and appendix to separate md files
	mdslides build ebook $(CONFIG) $(SOURCE) $(EBOOK_TMP)/ --glossary=$(GLOSSARY)
	# transclude all to one file 
	cd $(EBOOK_TMP); multimarkdown --to=mmd --output=../../docs/all.md single-page--master.md

	# build the site
	cd docs;jekyll build

epub:
	# render an ebook as epub
	$(update-make-conf)

	# render intro, chapters and appendix to separate md files
	mdslides build ebook $(CONFIG) $(SOURCE) $(EBOOK_TMP)/ --glossary=$(GLOSSARY) --section-prefix="$(SECTIONPREFIX)"

	# prepare and copy template
	$(MKTPL) templates/epub--master.md $(EBOOK_TMP)/epub--master.md $(LOC) $(PRJ)
	# transclude all to one file 
	cd $(EBOOK_TMP); multimarkdown --to=mmd --output=epub-compiled.md epub--master.md
	# render to epub
	cd $(EBOOK_TMP); pandoc epub-compiled.md -f markdown -t epub3 --toc --toc-depth=3 -s -o ../../$(TARGETFILE).epub

ebook:
	# render an ebook as pdf (via LaTEX)
	$(update-make-conf)
	
	# render intro, chapters and appendix to separate md files (but without sectionprefix!)
	mdslides build ebook $(CONFIG) $(SOURCE) $(EBOOK_TMP)/ --glossary=$(GLOSSARY) --no-section-prefix

	# copy md and LaTEX templates
	$(MKTPL) templates/ebook--master.md $(EBOOK_TMP)/ebook--master.md $(LOC) $(PRJ)
	$(MKTPL) config/ebook.tex $(EBOOK_TMP)/ebook.tex $(LOC) $(PRJ)
	$(MKTPL) config/ebook-style.sty $(EBOOK_TMP)/ebook-style.sty $(LOC) $(PRJ)

	# make an index
	mdslides index latex $(CONFIG) $(EBOOK_TMP)/tmp-index.md
	# transclude all to one file
	cd $(EBOOK_TMP); multimarkdown --to=mmd --output=tmp-ebook-compiled.md ebook--master.md

	cd $(EBOOK_TMP); multimarkdown --to=latex --output=tmp-ebook-compiled.tex tmp-ebook-compiled.md
	cd $(EBOOK_TMP); latexmk -pdf -xelatex -silent ebook.tex 
	cd $(TMPFOLDER)/ebook; mv ebook.pdf ../../$(TARGETFILE).pdf
	
	# clean up
	cd $(EBOOK_TMP); latexmk -C

gitbook:
	mdslides build gitbook $(CONFIG) $(SOURCE) gitbook/ --glossary=$(GLOSSARY)

update:
	$(update-make-conf)

clean:
	# clean all generated content
	-rm -r docs/img
	-rm -r docs/_site
	-rm docs/*.md
	# take no risk here!
	-rm -r tmp

setup:
	# prepare temp folders and jekyll site
	$(update-make-conf)
	# prepare temp folders
	echo "this might produce error output if folders already exist"
	-mkdir -p $(EBOOK_TMP)
	-mkdir -p $(DOCS_TMP)
	-mkdir -p $(TMPSUP)
	-mkdir docs/_site

	# images for ebook
ifneq ("$(wildcard $(EBOOK_TMP)/img)","")
	rm -r $(EBOOK_TMP)/img
endif
	cp -r img $(EBOOK_TMP)/img
	cp templates/covers/* $(EBOOK_TMP)/img

	# update version number in content
	$(MKTPL) templates/version.txt content/version.txt $(LOC) $(PRJ)

	# clean up and copy images do to docs folder
ifneq ("$(wildcard docs/img)","")
	rm -r docs/img
endif
	cp -r img docs/img

ifneq ("$(wildcard gitbook/img)","")
	# rm -r gitbook/img
endif
	# cp -r img gitbook/img
