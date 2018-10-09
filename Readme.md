# Kubernetes网络测试

## 集群访问公网测试

**测试说明**

- 镜像中将以下核心代码进行封装成为`curls`命令，使用方式`curls url [times]`，例如`curls choerodon.io 20`则为访问`choerodon.io`20次并打印测试出的时间指标，命令默认访问10次。

    ```bash
    curl -o /dev/null -s -w '%{time_connect} %{time_starttransfer} %{time_total}' "choerodon.io"
    ```

- 时间指标说明
  - 单位：秒
  - time_connect：建立到服务器的 TCP 连接所用的时间
  - time_starttransfer：在发出请求之后，Web 服务器返回数据的第一个字节所用的时间
  - time_total：完成请求所用的时间

### 场景一、 Kubernetes集群node节点访问公网

- 测试命令

    ```bash
    docker run -it --rm --net=host \
        registry.saas.hand-china.com/tools/network-tools \
        curls choerodon.io
    ```

- 测试结果

    ```
    No	time_connect	time_starttransfer	time_total
    1	0.015071	0.027448		0.027570
    2	0.010049	0.024527		0.024612
    3	0.010025	0.022209		0.022311
    4	0.012600	0.025269		0.025369
    5	0.012847	0.025849		0.025932
    6	0.009973	0.023102		0.023220
    7	0.013074	0.029310		0.029411
    8	0.015137	0.029992		0.030103
    9	0.010994	0.029040		0.029173
    10	0.010554	0.022011		0.022130
    ```

- 平均响应时间：26ms

### 场景二、Kubernetes集群Pod访问公网

- 测试命令

    ```bash
    kubectl run curl-test \
        -it --quiet --rm --restart=Never \
        --image='registry.saas.hand-china.com/tools/network-tools' \
        -- bash -c "sleep 3; curls choerodon.io"
    ```

- 测试结果

    ```
    No	time_connect	time_starttransfer	time_total
    1	0.014916	0.027232		0.027418
    2	0.020213	0.034626		0.034762
    3	0.014945	0.028014		0.028165
    4	0.016916	0.030483		0.032091
    5	0.020519	0.033075		0.033281
    6	0.015398	0.027727		0.028003
    7	0.015260	0.027099		0.027247
    8	0.019549	0.033506		0.033597
    9	0.020941	0.032935		0.035226
    10	0.014298	0.026570		0.026983
    ```

- 平均响应时间：29ms

## 集群内部网络延迟测试

**测试说明**

- 测试数据

    Service Name: default-http-backend.kube-system.svc

    Service Cluster IP: 10.233.48.173

    Service Port: 80

- 通过向`default-http-backend`的`healthz`api执行curl命令进行网络延迟测试

```Bash
$ curl "http://10.233.48.173/healthz"
ok
```

### 场景一、 Kubernetes集群node节点上通过Service Cluster IP访问

- 测试命令

    ```bash
    docker run -it --rm --net=host \
        registry.saas.hand-china.com/tools/network-tools \
        curls http://10.233.48.173/healthz
    ```

- 测试结果

    ```
    No	time_connect	time_starttransfer	time_total
    1	0.000491	0.000983		0.001038
    2	0.000347	0.002051		0.002122
    3	0.000298	0.000894		0.000975
    4	0.000263	0.082559		0.082665
    5	0.000351	0.000732		0.000785
    6	0.000234	0.084351		0.084445
    7	0.000245	0.000550		0.000592
    8	0.000436	0.086836		0.086947
    9	0.000215	0.000536		0.000573
    10	0.000369	0.089528		0.089635
    ```

- 平均响应时间：34ms

### 场景二、Kubernetes集群内部通过service访问

- 测试命令

    ```bash
    kubectl run curl-test \
        -it --quiet --rm --restart=Never \
        --image='registry.saas.hand-china.com/tools/network-tools' \
        -- bash -c "sleep 3; curls http://default-http-backend.kube-system.svc/healthz"
    ```

- 测试结果

    ```
    No	time_connect	time_starttransfer	time_total
    1	0.040173	0.080107		0.080205
    2	0.047826	0.065836		0.065932
    3	0.064808	0.091835		0.091938
    4	0.075448	0.087315		0.087410
    5	0.112765	0.195511		0.195640
    6	0.104970	0.199655		0.199777
    7	0.127144	0.139747		0.139834
    8	0.056066	0.063325		0.063456
    9	0.021773	0.028471		0.028578
    10	0.017777	0.023236		0.023330
    ```

- 平均响应时间：112ms

**注意：** 执行测试的node节点/Pod与Serivce所在的Pod的距离（是否在同一台主机上），对这两个场景可以能会有一定影响。

## 集群内部网络性能测试

**测试说明**

- 使用[iperf](https://docs.azure.cn/zh-cn/articles/azure-operations-guide/virtual-network/aog-virtual-network-iperf-bandwidth-test)进行测试.


### 场景一、主机之间

- 服务端命令：

    ```bash
    docker run -it --rm --net=host \
        registry.saas.hand-china.com/tools/network-tools \
        iperf -s -p 12345 -i 1 -M
    ```

- 客户端命令：

    ```bash
    docker run -it --rm --net=host \
        registry.saas.hand-china.com/tools/network-tools \
        iperf -c ${服务端主机IP} -p 12345 -i 1 -t 10 -w 20K
    ```

- 测试结果
    ```
    [ ID] Interval       Transfer     Bandwidth
    [  3]  0.0- 1.0 sec   225 MBytes  1.89 Gbits/sec
    [  3]  1.0- 2.0 sec   223 MBytes  1.87 Gbits/sec
    [  3]  2.0- 3.0 sec   237 MBytes  1.98 Gbits/sec
    [  3]  3.0- 4.0 sec   223 MBytes  1.87 Gbits/sec
    [  3]  4.0- 5.0 sec   273 MBytes  2.29 Gbits/sec
    [  3]  5.0- 6.0 sec   259 MBytes  2.17 Gbits/sec
    [  3]  6.0- 7.0 sec   308 MBytes  2.59 Gbits/sec
    [  3]  7.0- 8.0 sec   257 MBytes  2.16 Gbits/sec
    [  3]  8.0- 9.0 sec   261 MBytes  2.19 Gbits/sec
    [  3]  9.0-10.0 sec   234 MBytes  1.96 Gbits/sec
    [  3]  0.0-10.0 sec  2.44 GBytes  2.10 Gbits/sec
    ```

### 场景二、不同主机的Pod之间

- 服务端命令：

    ```bash
    kubectl run iperf-server \
        -it --quiet --rm --restart=Never \
        --overrides='{"spec":{"template":{"spec":{"nodeName":"指定服务端运行的节点"}}}}' \
        --image='registry.saas.hand-china.com/tools/network-tools' \
        -- bash -c "sleep 3; ifconfig eth0; iperf -s -p 12345 -i 1 -M"
    ```

**注意：**查看输出的日志，替换下面客户端命令中POD的IP

- 客户端命令：

    ```bash
    kubectl run iperf-client \
        -it --quiet --rm --restart=Never \
        --overrides='{"spec":{"template":{"spec":{"nodeName":"指定客户端运行的节点"}}}}' \
        --image='registry.saas.hand-china.com/tools/network-tools' \
        -- iperf -c ${服务端POD的IP} -p 12345 -i 1 -t 10 -w 20K
    ```

- 测试结果
    ```
    [ ID] Interval       Transfer     Bandwidth
    [  3]  0.0- 1.0 sec  1.42 GBytes  12.2 Gbits/sec
    [  3]  1.0- 2.0 sec  1.39 GBytes  11.9 Gbits/sec
    [  3]  2.0- 3.0 sec  1.22 GBytes  10.5 Gbits/sec
    [  3]  3.0- 4.0 sec  1.27 GBytes  10.9 Gbits/sec
    [  3]  4.0- 5.0 sec  1.04 GBytes  8.91 Gbits/sec
    [  3]  5.0- 6.0 sec  1.36 GBytes  11.7 Gbits/sec
    [  3]  6.0- 7.0 sec  1.42 GBytes  12.2 Gbits/sec
    [  3]  7.0- 8.0 sec  1.57 GBytes  13.5 Gbits/sec
    [  3]  8.0- 9.0 sec  1.25 GBytes  10.8 Gbits/sec
    [  3]  9.0-10.0 sec  1.56 GBytes  13.4 Gbits/sec
    [  3]  0.0-10.0 sec  13.5 GBytes  11.6 Gbits/sec
    ```

### 场景三、Node与非同主机的Pod之间


- 服务端命令：

    ```bash
    docker run -it --rm --net=host \
        registry.saas.hand-china.com/tools/network-tools \
        iperf -s -p 12345 -i 1 -M
    ```

- 客户端命令：

    ```bash
    kubectl run iperf-client \
        -it --quiet --rm --restart=Never \
        --overrides='{"spec":{"template":{"spec":{"nodeName":"指定客户端运行的节点"}}}}' \
        --image='registry.saas.hand-china.com/tools/network-tools' \
        -- iperf -c ${服务端主机IP} -p 12345 -i 1 -t 10 -w 20K
    ```

- 测试结果
    ```
    [ ID] Interval       Transfer     Bandwidth
    [  3]  0.0- 1.0 sec   289 MBytes  2.43 Gbits/sec
    [  3]  1.0- 2.0 sec   290 MBytes  2.43 Gbits/sec
    [  3]  2.0- 3.0 sec   226 MBytes  1.89 Gbits/sec
    [  3]  3.0- 4.0 sec   209 MBytes  1.75 Gbits/sec
    [  3]  4.0- 5.0 sec   254 MBytes  2.13 Gbits/sec
    [  3]  5.0- 6.0 sec   257 MBytes  2.15 Gbits/sec
    [  3]  6.0- 7.0 sec   265 MBytes  2.23 Gbits/sec
    [  3]  7.0- 8.0 sec   184 MBytes  1.55 Gbits/sec
    [  3]  8.0- 9.0 sec   217 MBytes  1.82 Gbits/sec
    [  3]  9.0-10.0 sec   236 MBytes  1.98 Gbits/sec
    [  3]  0.0-10.0 sec  2.37 GBytes  2.04 Gbits/sec
    ```

## 参考

- [Kubernetes网络和集群性能测试](https://jimmysong.io/kubernetes-handbook/practice/network-and-cluster-perfermance-test.html#)