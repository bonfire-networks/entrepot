ExUnit.start()

Mox.defmock(Entrepot.ExAwsMock, for: ExAws.Behaviour)

Application.put_env(:entrepot, Entrepot.Storages.S3, ex_aws_module: Entrepot.ExAwsMock, bucket: "")

Application.put_env(:entrepot, Entrepot.Storages.Disk, root_dir: "tmp")
