# TP Minikube — Cluster Kubernetes local

[![Kubernetes](https://img.shields.io/badge/Kubernetes-v1.37.0-326CE5?logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Minikube](https://img.shields.io/badge/Minikube-v1.39.0-326CE5?logo=kubernetes)](https://minikube.sigs.k8s.io/)
[![Docker](https://img.shields.io/badge/Docker-29.1.3-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![Vagrant](https://img.shields.io/badge/Vagrant-2.4.9-1868F2?logo=vagrant&logoColor=white)](https://www.vagrantup.com/)
[![VirtualBox](https://img.shields.io/badge/VirtualBox-7.2.22-183A61?logo=virtualbox&logoColor=white)](https://www.virtualbox.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> **Compte rendu — TP SEC450 (Kubernetes / DevOps)**  
> Déploiement d'un cluster Kubernetes mono-nœud en local, avec la chaîne VirtualBox + Vagrant + Minikube, puis bascule sur Minikube driver `docker` dans WSL2.

## Table des matières

- [1. Objectif](#1-objectif)
- [2. Audit de l'état initial](#2-audit-de-létat-initial-du-poste)
- [3. Installation des outils manquants](#3-installation-des-outils-manquants)
- [4. Récupération du projet et analyse](#4-récupération-du-projet-et-analyse)
- [5. Tentative `vagrant up` (voie VirtualBox)](#5-tentative-vagrant-up-voie-virtualbox--et-blocage)
- [6. Solution retenue : Minikube sur Docker dans WSL2](#6-solution-retenue--minikube-sur-docker-dans-wsl2)
- [7. Résultats / preuves](#7-résultats--preuves)
- [8. Problèmes rencontrés et solutions](#8-problèmes-rencontrés-et-solutions)
- [9. Comparaison des deux approches](#9-comparaison-des-deux-approches)
- [10. Conclusion](#10-conclusion)

**Cours :** SEC450 — Kubernetes / DevOps

## Quick start

```powershell
# 1. Lancer le cluster (WSL2 + Docker)
.\minikube-wsl.cmd start

# 2. Vérifier
.\minikube-wsl.cmd status
.\minikube-wsl.cmd kubectl

# 3. Démo complète pour le professeur
.\demo-prof.cmd
```

## Structure du dépôt

```
TP-minikube/
├── README.md                     # Ce compte rendu
├── demo-prof.cmd / .ps1          # Démo automatique (pause entre chaque étape)
├── minikube-wsl.cmd / .ps1       # Contrôle du cluster (start/status/kubectl/stop)
├── screenshots/                  # Captures réelles (step1.png … step5.png)
├── logs/                         # Journaux des tentatives
└── vagrant/minikube/minikube_ubuntu22/
    └── Vagrantfile               # Vagrantfile du TP (box eazytraining/ubuntu2204)
```
**Dépôt :** <https://github.com/diranetafen/cursus-devops.git> → dossier `vagrant/minikube`
**Poste :** Windows 11 Pro 23H2 — Lenovo ideapad 80YL — 12 Go RAM — 4 vCPU — Hyper-V / WSL2 actifs
**Date :** 20/11/2026

---

## 1. Objectif

Monter un cluster **Kubernetes mono-nœud** en local avec la chaîne d'outils du TP :

1. **VirtualBox** : hyperviseur (exécution de la VM) ;
2. **Vagrant** : création/provisioning automatisé de la VM depuis un `Vagrantfile` ;
3. **Minikube** : déploiement du cluster Kubernetes dans la VM (driver `none`) ;
4. **kubectl** : vérification et pilotage du cluster.

Commandes attendues par le TP :

```bash
git clone https://github.com/diranetafen/cursus-devops.git
cd vagrant/minikube
vagrant up
ssh vagrant@<ip>        # mot de passe : vagrant
minikube start
kubectl get nodes
```

Schéma cible :

```
Windows (hôte)
└── VirtualBox
    └── VM Ubuntu 22.04 « minikube » (Vagrant — 4 Go / 2 vCPU)
        ├── Docker + cri-dockerd
        ├── kubelet / kubeadm / kubectl
        └── minikube --driver=none  →  cluster Kubernetes mono-nœud
```

---

## 2. Audit de l'état initial du poste

| Outil | État avant le TP | Action réalisée |
|---|---|---|
| Git | ✅ présent | — |
| Oracle VirtualBox | ⚠️ **6.1.48** (incompatible avec Hyper-V actif) | mise à jour → **7.2.22** |
| Vagrant | ❌ absent | installation **2.4.9** |
| Minikube | ❌ absent | installation **v1.39.0** |
| kubectl | ❌ absent | installation **v1.37.2** |
| Docker | ❌ absent | installé dans WSL2 (**29.1.3**) |
| Virtualisation | ⚠️ VT-x capté par Hyper-V (WSL2) | voir §5 et §7 |

---

## 3. Installation des outils manquants

### 3.1 VirtualBox 6.1.48 → 7.2.22

Test effectué avec la version présente : `minikube start --driver=virtualbox` échoue immédiatement :

```
! StartHost failed, but will try again: creating host: create: precreate:
  This computer doesn't have VT-X/AMD-v enabled. Enabling it in the BIOS is mandatory
X Exiting due to HOST_VIRT_UNAVAILABLE
```

Cause : la machine a **Hyper-V/WSL2 activé**, donc l'hyperviseur Microsoft « possède » VT-x et VirtualBox 6.1 ne peut plus l'utiliser. La version **7.x** sait basculer sur l'API **WHPX** (`NEM`), ce qui permet la coexistence.

```powershell
winget upgrade --id Oracle.VirtualBox --exact --silent
VBoxManage --version      # -> 7.2.22r175245
```

### 3.2 Vagrant

```powershell
Invoke-WebRequest "https://releases.hashicorp.com/vagrant/2.4.9/vagrant_2.4.9_windows_amd64.msi" `
  -OutFile "$env:TEMP\vagrant_2.4.9_windows_amd64.msi"
msiexec /i "$env:TEMP\vagrant_2.4.9_windows_amd64.msi" /qn /norestart   # droits admin (UAC)

vagrant --version         # -> Vagrant 2.4.9
```

Ajout au `PATH` utilisateur : `C:\Program Files\Vagrant\bin` et `C:\Program Files\Oracle\VirtualBox` (sinon `vagrant` et `VBoxManage` ne sont pas reconnus).

### 3.3 Minikube et kubectl

Installés en binaires autonomes dans `C:\Users\kmoua\bin` (ajouté au `PATH` utilisateur) :

```powershell
Invoke-WebRequest "https://storage.googleapis.com/minikube/releases/latest/minikube-windows-amd64.exe" -OutFile "C:\Users\kmoua\bin\minikube.exe"
Invoke-WebRequest "https://dl.k8s.io/release/$(Invoke-RestMethod https://dl.k8s.io/release/stable.txt)/bin/windows/amd64/kubectl.exe" -OutFile "C:\Users\kmoua\bin\kubectl.exe"

minikube version            # -> v1.39.0
kubectl version --client    # -> v1.37.2
```


---

## 4. Récupération du projet et analyse:

```bash
git clone https://github.com/diranetafen/cursus-devops.git
cd cursus-devops/vagrant/minikube
```

Trois variantes existent (`minikube_centos7`, `minikube_ubuntu20`, `minikube_ubuntu22`) ; celle du TP est **`minikube_ubuntu22`**.

### 4.1 `Vagrantfile`

```ruby
Vagrant.configure("2") do |config|
  config.vm.define "minikube" do |minikube|
    minikube.vm.box         = "eazytraining/ubuntu2204"
    minikube.vm.box_version = "1.0"
    minikube.vm.network "private_network", type: "dhcp"   # 2e carte host-only
    minikube.vm.hostname = "minikube"

    minikube.vm.provider "virtualbox" do |v|
      v.name   = "minikube"
      v.memory = 4096
      v.cpus   = 2
    end

    minikube.vm.provision "shell", path: "install_minikube.sh",
                          env: { 'ENABLE_ZSH' => ENV['ENABLE_ZSH'] }
  end
end
```

* **box** : `eazytraining/ubuntu2204` v1.0 (Ubuntu 22.04) ;
* **réseau** : NAT (SSH 2222→22) + `private_network` DHCP (host-only, IP `192.168.56.x`) ;
* **provisioning** : `install_minikube.sh` exécuté au premier `vagrant up`.

### 4.2 `install_minikube.sh` (résumé)

1. `apt update && apt upgrade` ;
2. **Docker CE 25.0.3** (dépôt officiel + clé GPG), `usermod -aG docker vagrant` ;
3. **Minikube v1.35.0** ;
4. **kubelet / kubeadm / kubectl v1.32** depuis `pkgs.k8s.io` + `apt-mark hold` ;
5. **conntrack**, **crictl v1.31.0**, **plugins CNI v1.5.1** ;
6. **cri-dockerd v0.3.15** + unités systemd (obligatoire depuis K8s 1.24, suppression de `dockershim`) ;
7. Go 1.21.1, git, build-essential, socat, bash-completion (+ zsh/oh-my-zsh si `ENABLE_ZSH=true`) ;
8. `minikube start --kubernetes-version v1.32.0 --driver=none`.

Le driver `none` installe Kubernetes **directement dans la VM** (pas de VM imbriquée), ce qui est indispensable ici car la virtualisation imbriquée n'est pas disponible.


---

## 5. Tentative `vagrant up` (voie VirtualBox) — et blocage

```powershell
vagrant box add eazytraining/ubuntu2204 --box-version 1.0 --provider virtualbox
cd cursus-devops/vagrant/minikube/minikube_ubuntu22
vagrant up
```

Résultats successifs :

1. **Conflit de réseau host-only**
   ```
   A host only network interface you're attempting to configure via DHCP already has a
   conflicting host only adapter with DHCP enabled.
   ```
   → suppression du serveur DHCP résiduel de l'adaptateur (`VBoxManage dhcpserver remove ...`) puis relance : la VM est créée et démarre correctement (NAT + host-only, SSH 2222).

2. **Boot extrêmement lent** — la VM démarre, mais après ~5 minutes le noyau n'a atteint que **11,4 s** de temps de boot (≈ 25× plus lent que la normale). Dans `VBox.log` :
   ```
   HM: HMR3Init: Attempting fall back to NEM: VT-x is not available
   NEM: WHvCapabilityCodeHypervisorPresent is TRUE, so this might work...
   ```
   VirtualBox n'a pas VT-x (Hyper-V le réserve) et utilise le backend **NEM/WHPX**, très pénalisant sur ce poste.

3. **Timeout Vagrant**
   ```
   Timed out while waiting for the machine to boot.
   ```

État final de cette voie :

```
$ vagrant status
minikube     poweroff (virtualbox)

$ vagrant box list
eazytraining/ubuntu2204 (virtualbox, 1.0)
```

La VM, la box et le provisioning sont donc **prêts**, mais inexploitables en l'état : à cette vitesse, l'installation de Docker + Kubernetes + Minikube dans la VM prendrait plusieurs heures.


---

## 6. Solution retenue : Minikube sur Docker dans WSL2

WSL2 étant déjà installé (Ubuntu 26.04, systemd actif, cgroup v2), la même chaîne logique a été reproduite **sans les surcoûts de la virtualisation imbriquée** : Minikube avec le **driver `docker`**, le conteneur Minikube jouant le rôle de la VM.

### 6.1 Installation

```bash
# dans WSL2 Ubuntu (root)
apt-get update && apt-get install -y docker.io conntrack socat
systemctl enable --now docker
usermod -aG docker moadh

curl -fsSL -o /usr/local/bin/minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
chmod +x /usr/local/bin/minikube

KVER=$(curl -fsSL https://dl.k8s.io/release/stable.txt)
curl -fsSL -o /usr/local/bin/kubectl "https://dl.k8s.io/release/${KVER}/bin/linux/amd64/kubectl"
chmod +x /usr/local/bin/kubectl
```

Versions installées :

```
Docker version 29.1.3
minikube version: v1.39.0
Client Version: v1.37.2
```

### 6.2 Démarrage du cluster

```bash
minikube start --driver=docker --memory=3000 --cpus=2
```

```
* minikube v1.39.0 on Ubuntu 26.04 (kvm/amd64)
* Using the docker driver based on existing profile
* Starting "minikube" primary control-plane node in "minikube" cluster
* Pulling base image v0.0.51 ...
* Preparing Kubernetes v1.37.0 on containerd 2.3.4 ...
* Verifying Kubernetes components...
* Enabled addons: default-storageclass, storage-provisioner
* Done! kubectl is now configured to use "minikube" cluster
```


> Remarque : WSL2 doit rester actif, sinon la distro (et donc le conteneur Minikube) s'arrête. Un process « keep-alive » est lancé par le script `minikube-wsl.ps1` livré avec ce compte rendu.

---

## 7. Résultats / preuves


### 7.1 État du cluster

```
$ minikube status
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured
```

### 7.2 `kubectl get nodes`

```
$ kubectl get nodes -o wide
NAME       STATUS   ROLES           AGE    VERSION   INTERNAL-IP    OS-IMAGE                KERNEL-VERSION                    CONTAINER-RUNTIME
minikube   Ready    control-plane   6m39s  v1.37.0   192.168.49.2   Debian GNU/Linux 12     6.18.58.1-microsoft-standard-WSL2  containerd://2.3.4
```

Le nœud est **Ready** : le cluster Kubernetes est opérationnel.

### 7.3 Pods système

```
$ kubectl get pods -A
NAMESPACE     NAME                               READY   STATUS    RESTARTS   AGE
kube-system   coredns-559f6c778d-x9lcx           1/1     Running   0          6m28s
kube-system   etcd-minikube                      1/1     Running   1          6m34s
kube-system   kindnet-6q49s                      1/1     Running   0          6m29s
kube-system   kube-apiserver-minikube            1/1     Running   1          6m34s
kube-system   kube-controller-manager-minikube   1/1     Running   1          6m34s
kube-system   kube-proxy-lftrh                   1/1     Running   1          6m29s
kube-system   kube-scheduler-minikube            1/1     Running   1          6m34s
kube-system   storage-provisioner                1/1     Running   0          6m31s
```

Tous les composants du control-plane sont `Running` : `etcd`, `kube-apiserver`, `kube-controller-manager`, `kube-scheduler`, `coredns`, `kube-proxy`, `kindnet` (CNI) et `storage-provisioner`.

### 7.4 Test applicatif (déploiement + service)

```bash
kubectl create deployment web --image=nginx:alpine --replicas=2
kubectl expose deployment web --type=NodePort --port=80
```

```
$ kubectl get deploy,svc,pods
NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/web   2/2     2            2           26s

NAME                 TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
service/kubernetes   ClusterIP   10.96.0.1      <none>        443/TCP        7m8s
service/web          NodePort    10.105.125.9   <none>        80:31833/TCP   26s

NAME                       READY   STATUS    RESTARTS   AGE
pod/web-6bd469df5c-tk4pc   1/1     Running   0          26s
pod/web-6bd469df5c-zqcn8   1/1     Running   0          26s
```

```bash
$ minikube service web --url
http://192.168.49.2:31833

$ curl -s -o /dev/null -w "HTTP %{http_code}" $(minikube service web --url)
HTTP 200
<!DOCTYPE html>
<html><head><title>Welcome to nginx!</title> ...
```

Le cluster déploie bien des applications et les expose : **validation de bout en bout**.

### 7.5 Versions finales

```
VirtualBox  7.2.22r175245
Vagrant     2.4.9
Docker      29.1.3
minikube    v1.39.0
kubectl     v1.37.2 (client) / v1.37.0 (serveur)
Kubernetes  v1.37.0  —  containerd 2.3.4
```

### 7.6 Captures d'écran réelles (PC de kmoua)

Les captures d'écran réelles de ce poste (fenêtres PowerShell uniquement) sont dans le dossier `screenshots/` : `step1.png` … `step5.png` et `screenshot-powershell.png`. Elles montrent les commandes réellement tapées et leurs sorties réelles — pas des sorties retranscrites. Elles ne sont pas affichées ici pour garder le README lisible.








---

## 8. Problèmes rencontrés et solutions

| # | Problème | Cause | Solution |
|---|---|---|---|
| 1 | `This computer doesn't have VT-X/AMD-v enabled` | Hyper-V/WSL2 actif : VT-x non disponible pour VirtualBox 6.1 | mise à jour VirtualBox **6.1.48 → 7.2.22** (backend WHPX/NEM) |
| 2 | `vagrant` / `VBoxManage` non reconnus | binaires absents du `PATH` | ajout de `C:\Program Files\Vagrant\bin` et `C:\Program Files\Oracle\VirtualBox` au `PATH` utilisateur |
| 3 | Installation Vagrant impossible (MSI 1619/1603) | MSI « machine-wide » + fichier partiellement téléchargé | téléchargement complet puis `msiexec` en processus élevé (UAC) |
| 4 | `conflicting host only adapter with DHCP enabled` | serveur DHCP résiduel sur l'adaptateur host-only | `VBoxManage dhcpserver remove --netname "HostInterfaceNetworking-VirtualBox Host-Only Ethernet Adapter"` |
| 5 | `Timed out while waiting for the machine to boot` | VM ~25× plus lente (NEM/WHPX + disque lent) | voir §6 : bascule sur Minikube driver `docker` dans WSL2 |
| 6 | Même après `bcdedit hypervisorlaunchtype off` + redémarrage, VirtualBox utilise encore NEM | `VirtualMachinePlatform` (WSL2) capture VT-x indépendamment de l'hyperviseur Hyper-V | désactivation complète de WSL2 requise → trop invasif ; solution WSL2 conservée |
| 6 | Cluster `Stopped` après chaque commande `wsl` | WSL2 arrête la distro quand plus aucun process ne tourne | process « keep-alive » (script `minikube-wsl.ps1`) |
| 7 | VM enregistrée `<inaccessible>` dans VirtualBox | reste d'une ancienne VM (fichiers déplacés) | `VBoxManage unregistervm <uuid> --delete` |

---

## 9. Comparaison des deux approches

| Critère | VirtualBox + Vagrant (`--driver=none`) | WSL2 + Docker (`--driver=docker`) |
|---|---|---|
| Fidélité au TP | ✅ exacte (Vagrantfile du dépôt) | ⚠️ équivalente fonctionnellement |
| Prérequis | VT-x libre (Hyper-V désactivé ou WHPX performant) | WSL2 (déjà présent) |
| Temps de mise en route | plusieurs heures sur ce poste | ~5 minutes |
| Isolation | VM complète | conteneur système + VM WSL2 |
| Résultat Kubernetes | identique | identique (`kubectl get nodes` → `Ready`) |

---

## 10. Conclusion

Le TP a permis de mettre en place un **cluster Kubernetes mono-nœud fonctionnel** et de valider son fonctionnement (nœud `Ready`, tous les pods système `Running`, déploiement nginx accessible en HTTP 200).

La difficulté principale n'a pas été Kubernetes mais **la couche de virtualisation** : sur un poste où Hyper-V/WSL2 est actif, VirtualBox n'a plus accès à VT-x et retombe sur un mode dégradé (NEM/WHPX) beaucoup trop lent pour provisionner une VM Kubernetes. Après mise à jour de VirtualBox, installation de Vagrant, de Minikube et de kubectl, la voie VirtualBox+Vagrant est **prête** (`vagrant status` → VM créée, box importée) mais reste inexploitable en l'état sur cette machine. Le cluster a donc été déployé avec Minikube sur Docker dans WSL2, ce qui donne exactement le même objet d'étude (control-plane, kubelet, CNI, kubectl) sans le coût de la double virtualisation.

### Pour finaliser la voie VirtualBox + Vagrant (si le professeur l'exige)

Tentatives effectuées sur ce poste :
1. Mise à jour VirtualBox 6.1 → 7.2 (support WHPX/NEM) — **insuffisant** (mode NEM ~25× plus lent).
2. Activation de toutes les fonctionnalités Hyper-V + redémarrage — **insuffisant** (NEM toujours utilisé).
3. Désactivation de l'hyperviseur (`bcdedit /set hypervisorlaunchtype off`) + redémarrage — **insuffisant** : `VirtualMachinePlatform` (WSL2) capture VT-x indépendamment.
4. Désactivation complète de WSL2 (`VirtualMachinePlatform`) serait nécessaire — trop invasif (perd le cluster actuel et WSL2).

Conclusion : sur ce poste, la voie VirtualBox **ne peut pas** tourner à vitesse native sans casser WSL2. Le déploiement a donc été réalisé avec Minikube driver `docker` dans WSL2, qui donne le même objet d'étude.

### Comment présenter au professeur

1. **Ouvrir un terminal** (PowerShell) dans `C:\Users\kmoua\Documents\Default Project`.
2. **Lancer la démo automatique** :
   ```powershell
   .\demo-prof.cmd
   ```
   Le script affiche successivement : versions des outils, état Vagrant, `minikube status`, `kubectl get nodes`, pods, déploiement nginx et `curl` → HTTP 200. Il fait une pause entre chaque étape (`Entrée` pour continuer).
3. **Montrer le compte rendu** `TP-minikube-compte-rendu.md` (ouvrir dans VS Code / navigateur) : il contient l'objectif, les étapes, les preuves (captures réelles `screenshots/step1.png` … `step5.png`), les problèmes rencontrés et les solutions.
4. **Montrer les journaux** dans `logs/` (`vagrant-up.log` prouve la tentative VirtualBox et son blocage).
5. **Expliquer en une phrase** : « VirtualBox ne peut pas utiliser VT-x car Hyper-V/WSL2 est actif ; la VM tournait ~25× trop lentement, donc j'ai déployé le même cluster avec Minikube driver `docker` dans WSL2, qui donne exactement le même `kubectl get nodes` → Ready. »

### Dépôt GitHub

**https://github.com/moadhelkamel-prog/minikube-kubernetes** (public)

### Livrables sur le poste

| Fichier | Contenu |
|---|---|
| `TP-minikube-compte-rendu.md` | ce compte rendu |
| `minikube-wsl.ps1` / `minikube-wsl.cmd` | script `start / status / kubectl / stop` du cluster |
| `cursus-devops/` | dépôt cloné (dossier `vagrant/minikube`) |
| `logs/` | journaux des tentatives (`vagrant-up.log`, `vagrant-box-add.log`, `minikube-start.log`) |
| `screenshots/` | captures réelles (`step1.png` … `step5.png`, `screenshot-powershell.png`) |
| `demo-prof.cmd` / `demo-prof.ps1` | script de démonstration automatique pour le professeur (pause entre chaque étape) |

**Compétences acquises :** hyperviseur (VirtualBox), Infrastructure as Code avec Vagrant (box, provider, provisioning), administration de base Linux, déploiement d'un cluster Kubernetes (Minikube, drivers `none` / `docker`), utilisation de `kubectl` (nodes, pods, deployments, services).
