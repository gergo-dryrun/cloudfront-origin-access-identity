package_code:
	rm -rf code/publish/create_oai/
	mkdir -p code/publish/create_oai
	cp -r code/create_oai code/publish/
	pip install -t code/publish/create_oai -r code/publish/create_oai/requirements.txt
	cd code/publish/create_oai && zip -r ../create_oai.zip .

deps:
	@which jq || ( which brew && brew install jq || which apt-get && apt-get install jq || which yum && yum install jq || which choco && choco install jq)
	@which aws || pip install awscli

deploy: clean package_code deps
	mkdir -p template/publish
	aws cloudformation package --template-file template/cloudfront-oai.template --s3-bucket $(BUCKET_NAME) --s3-prefix cloudfront-oai/lambda --output-template-file template/publish/cloudfront-oai.template
	aws cloudformation package --template-file template/demo-stack.template --s3-bucket $(BUCKET_NAME) --s3-prefix demo-stack/template --output-template-file template/publish/demo-stack.template
	aws cloudformation deploy --template-file template/publish/demo-stack.template --stack-name $(STACK_NAME) --parameter-overrides `cat parameters/demo-stack.json | jq -c --raw-output '.[] | [.ParameterKey + "=" + .ParameterValue] | @tsv'` --capabilities CAPABILITY_NAMED_IAM
	make clean

clean:
	@echo "--> Cleaning up from previous deployment."
	find . -name "*.pyc" -delete
	rm -rf code/publish
	rm -rf template/publish
	@echo ""
