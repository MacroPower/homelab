import os
import base64
import requests
import logging
from sys import exit
from urllib.parse import urljoin
from kubernetes import client, config

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# pip install git+https://github.com/kubernetes-client/python.git

dd_url_base = os.getenv("DEFECTDOJO_URL")
dd_username = os.getenv("DEFECTDOJO_USERNAME")
dd_password = os.getenv("DEFECTDOJO_PASSWORD")
dd_headers = {"accept": "application/json", "Content-Type": "application/json"}

k8s_secret_name = "defectdojo-api-token"
k8s_secret_namespace = "defectdojo"


def main():
    config.load_incluster_config()

    dd_url = urljoin(dd_url_base, "/api/v2/api-token-auth/")

    logger.info(f"Getting API token from {dd_url}")
    token_response = requests.post(
        dd_url,
        headers=dd_headers,
        json=dict(
            username=dd_username,
            password=dd_password,
        ),
        verify=False,
    )

    try:
        token_response.raise_for_status()
        api_token = token_response.json().get("token")
    except Exception as e:
        logger.exception("Failed to get API token")
        logger.error(f"Response : {token_response.status_code} : {token_response.content}")
        exit(1)

    data = {
        "DEFECTDOJO_URL": os.getenv("DEFECTDOJO_URL"),
        "DEFECTDOJO_USERNAME": os.getenv("DEFECTDOJO_USERNAME"),
        "DEFECTDOJO_API_TOKEN": api_token,
    }

    api_instance = client.CoreV1Api()

    encoded_data = {
        k: base64.b64encode(v.encode("utf-8")).decode("utf-8") for k, v in data.items()
    }

    # Define the secret
    secret = client.V1Secret(
        metadata=client.V1ObjectMeta(name=k8s_secret_name), data=encoded_data
    )

    try:
        # Try to create the secret
        api_instance.create_namespaced_secret(k8s_secret_namespace, secret)
        logger.info("Secret created!")
    except client.rest.ApiException as e:
        if e.status == 409:
            # Secret already exists, update it
            api_instance.replace_namespaced_secret(
                k8s_secret_name, k8s_secret_namespace, secret
            )
            logger.info("Secret updated!")
        else:
            raise


if __name__ == "__main__":
    main()
