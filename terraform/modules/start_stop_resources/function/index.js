const AWS = require('aws-sdk')
const ec2 = new AWS.EC2();
const rds = new AWS.RDS();
const ecs = new AWS.ECS();

const ec2StopParams = {
  InstanceIds: [
    process.env.EC2_TOOLING_ID,
    process.env.EC2_NAT_ID,
    process.env.EC2_BASTION_ID
  ]
}

const ec2StartParams = {
  InstanceIds: [
    process.env.EC2_NAT_ID,
    process.env.EC2_BASTION_ID
  ]
}

const rdsParams = {
  DBInstanceIdentifier: process.env.RDS_CORE_ID
}

const ecsServicesParams = {
  apiCore: {
    cluster: process.env.ECS_CLUSTER_NAME,
    service: process.env.ECS_SERVICES_API_CORE_NAME
  },
  appCommunity: {
    cluster: process.env.ECS_CLUSTER_NAME,
    service: process.env.ECS_SERVICES_APP_COMMUNITY_NAME
  },
}

// 常時稼働させたくないリソースの停止
exports.stopResources = async function(event, context) {
  console.log("EVENT: \n" + JSON.stringify(event, null, 2))
  try {
    await ec2.stopInstances(ec2StopParams).promise();
  } catch(err) {
    console.error(err);
  }

  try {
    result =  await ecs.updateService(Object.assign({desiredCount: 0}, ecsServicesParams.apiCore)).promise();
    console.log(result)
    await ecs.updateService(Object.assign({desiredCount: 0}, ecsServicesParams.appCommunity)).promise();
  } catch(err) {
    console.error(err);
  }

  try {
    rdsCore = await rds.describeDBInstances(rdsParams).promise();
    if (rdsCore.DBInstances[0].DBInstanceStatus !== "stopped") {
      await rds.stopDBInstance(rdsParams).promise();
    }
  } catch(err) {
    console.error(err);
  }

  return 
}

// stopResourcesで停止したリソースの開始
exports.startResources = async function(event, context) {
  console.log("EVENT: \n" + JSON.stringify(event, null, 2))
  try {
    await ec2.startInstances(ec2StartParams).promise();
  } catch(err) {
    console.error(err);
  }

  try {
    await ecs.updateService(Object.assign({desiredCount: 1}, ecsServicesParams.apiCore)).promise();
    await ecs.updateService(Object.assign({desiredCount: 1}, ecsServicesParams.appCommunity)).promise();
  } catch(err) {
    console.error(err);
  }

  try {
    rdsCore = await rds.describeDBInstances(rdsParams).promise();
    if (rdsCore.DBInstances[0].DBInstanceStatus === "stopped") {
      await rds.startDBInstance(rdsParams).promise();
    }
  } catch(err) {
    console.error(err);
  }
 
  return 
}
