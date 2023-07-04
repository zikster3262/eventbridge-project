create:
		terraform init; terraform plan; terraform apply -auto-approve

plan:
		terraform init; terraform plan

destroy:
	terraform destroy -auto-approve