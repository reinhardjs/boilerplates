### How to configure Traefik to handle domain names and SSL certificates

First, create a secret for the SSL certificate and key:

```bash
sudo kubectl create secret tls reinhardjs-my-id-tls-secret --cert=/etc/ssl/reinhardjs.my.id.crt --key=/etc/ssl/reinhardjs.my.id.key
```

Then setup an ingress route for the domain name:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-web-ingress
  namespace: default
  annotations:
    traefik.ingress.kubernetes.io/ssl-cert: "reinhardjs-my-id-tls-secret" # Reference the secret
    traefik.ingress.kubernetes.io/ssl-redirect: "true" # Enforce HTTPS
spec:
  rules:
  - host: reinhardjs.my.id
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-web
            port:
              number: 3000
  tls:
  - hosts:
    - reinhardjs.my.id
      secretName: reinhardjs-my-id-tls-secret
```
