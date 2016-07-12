#!/usr/bin/python


def set_node_reuse(item, job, params):
    print "zuul_functions: set_node_reuse(", item, job, "): "
    params['OFFLINE_NODE_WHEN_COMPLETE'] = '0'


def set_node_options(item, job, params):
    if job.name in ('config-check', 'config-update'):
        # Prevent putting master node offline
        params['OFFLINE_NODE_WHEN_COMPLETE'] = '0'
        return
    print "zuul_functions: set_node_options(", item, job, "): "
    params['OFFLINE_NODE_WHEN_COMPLETE'] = '1'

    # Override Zuul's LOG_PATH to use ZUUL_REF as unique identifier
    # instead of ZUUL_UUID. ZUUL_REF is unique across a job build set
    # while ZUUL_UUID is unique per job. Uploading based on ZUUL_REF
    # allows child jobs to find parent jobs artifacts easily.
    ref_uuid = params['ZUUL_REF'].split('/')[-1]
    params['LOG_PATH'] = "{base}/{pipeline}/{job}/{ref}".format(
        base=params['BASE_LOG_PATH'],
        pipeline=params['ZUUL_PIPELINE'],
        job=job.name,
        ref=ref_uuid
    )
