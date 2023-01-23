# --------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for
# license information.
# --------------------------------------------------------------------------

import os
import json
from azure.identity import ManagedIdentityCredential
from azure.mgmt.cosmosdb import CosmosDBManagementClient
from azure.cosmos import CosmosClient


def _format(content):
    return json.dumps(content.serialize(keep_readonly=True), indent=4, separators=(',', ': '))


def main():
    SUBSCRIPTION_ID = os.environ.get("SUBSCRIPTION_ID", None)
    RESOURCE_GROUP_NAME = os.environ.get("RESOURCE_GROUP_NAME", None)
    CLIENT_ID = os.environ.get("MANAGED_IDENTITY_CLIENT_ID")
    DATABASE_ACCOUNT= os.environ.get("DATABASE_ACCOUNT")
    DATABASE_NAME = 'programcreateddb'

    cosmosdb_client = CosmosDBManagementClient(
        credential=ManagedIdentityCredential(client_id=CLIENT_ID),
        subscription_id=SUBSCRIPTION_ID
    )

    # Get database account
    database_account = cosmosdb_client.database_accounts.get(
        RESOURCE_GROUP_NAME,
        DATABASE_ACCOUNT
    )

    print("Get database account:\n{}".format(_format(database_account)))

    # Create database under database account
    # Create sql database
    database = cosmosdb_client.sql_resources.begin_create_update_sql_database(
        RESOURCE_GROUP_NAME,
        DATABASE_ACCOUNT,
        DATABASE_NAME,
        {
          "location": "eastus",
          "resource": {
            "id": DATABASE_NAME
          },
          "options": {
            "throughput": "2000"
          }
        }
    ).result()
    print("Create sql database:\n{}".format(database))

    # List database metrics
    database = cosmosdb_client.database.list_metrics(
        RESOURCE_GROUP_NAME,
        DATABASE_ACCOUNT,
        DATABASE_NAME,
        "(name.value eq 'Available Storage' or name.value eq 'Data Size' or name.value eq 'Index Size') and timeGrain eq duration'PT5M'"
    )
    for item in database:
        print("Get database:\n{}".format(_format(item)))


if __name__ == "__main__":
    main()