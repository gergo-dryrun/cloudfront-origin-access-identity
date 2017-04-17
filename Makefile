package_code:
	rm -rf code/publish/create_oai/
	mkdir -p code/publish/create_oai
	cp -r code/create_oai code/publish/
	pip install -t code/publish/create_oai -r code/publish/create_oai/requirements.txt
	cd code/publish/create_oai && zip -r ../create_oai.zip .

deploy: clean package_code
    mkdir template/publish/
	aws cloudformation package --template-file template/cloudfront-oai.template --s3-bucket $(BUCKET_NAME) --s3-prefix cloudfront-oai/lambda --output-template-file template/publish/cloudfront-oai.template
	aws cloudformation package --template-file template/demo-stack.template --s3-bucket $(BUCKET_NAME) --s3-prefix demo-stack/template --output-template-file template/publish/demo-stack.template

clean:
	@echo "--> Cleaning pyc files"
	find . -name "*.pyc" -delete
	rm -rf code/publish
	rm -f template/publish
	@echo ""
