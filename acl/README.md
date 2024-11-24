Approach to ensure that files in a directory automatically get set to specific permissions and ownership. The two main alternatives involve using ACLs (Access Control Lists) or automating permissions and ownership settings with systemd or auditd. I'll explain both methods:

## Using ACL (Access Control Lists)

ACL allows for more granular control of file permissions and can be used to enforce specific permissions automatically on files within a directory.

- Set Default ACLs on a Directory:

    You can use ACLs to set default permissions and ownership for files created within a specific directory, so every time a file is created or modified, it will inherit those settings.

    To set default permissions using ACL:

    1. Install acl package (if not already installed):
        ```
        sudo apt update
        sudo apt install acl
        ```

    2. Set Default ACL for a Directory:
        ```
        sudo setfacl -d -m u::rwx /path/to/your/directory   # Default permissions for the owner (root)
        sudo setfacl -d -m g::rwx /path/to/your/directory   # Default permissions for the group (users)
        sudo setfacl -d -m o::rwx /path/to/your/directory   # Default permissions for others (world)
        ```

        - The -d option means these ACL rules apply to new files created in the directory, not existing ones.
        - Replace /path/to/your/directory with the actual path.

    3. Set Default ACL for Group users: To ensure files have the correct group ownership, you can also set a default ACL for the group:
        ```
        sudo setfacl -d -m g:users:rwx /path/to/your/directory
        ```

    4. Verify ACLs: To check the default ACL settings for the directory:

        ```
        getfacl /path/to/your/directory
        ```

## Advantages of ACLs:

- Granular Control: You can specify exactly which users or groups should have access.
- No Need for a Script: You set up ACLs once, and they work automatically without needing to monitor the directory with a script.

## Limitations of ACLs:

- ACLs can add complexity and might not be available or supported on all file systems (e.g., NFS).
- You still need to ensure that files are created with the correct group ownership.
