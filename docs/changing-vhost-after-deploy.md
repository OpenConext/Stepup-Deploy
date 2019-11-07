The hostnames by which users access the Stepup-* applications are set using the vhost_* Ansible variables in the all.yml group vars. Because these vhost names are used as part of configuration filenames changing the name of a vhost requires manual steps.

1. Update the vhost name in the environment in all.yml
2. When required, update the TLS client certificates associated with the vhosts
3. Redeploy site.yml. You can economise by limiting the deploy to some tags: common, app, proxy and manage
4. Remove the .conf files with the old vhost names from /etc/nginx/conf.d and reload the nginx service
5. Remove the .conf files with the old vhost names from /etc/php-fpm/conf.d and restart the php-fpm service
6. Deploy the Stepup-* applications for which the vhost names changed
7. Push the middleware configuraton
8. Cleanup: Remove the symlinks in /opt/www with the old vhost names
9. Update DNS, and deplending on which vhosts changed: the remote IdP configuration, the configuration of connected SPs an external loadbalancer
