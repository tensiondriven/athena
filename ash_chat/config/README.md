# Configuration Files

## Personal Setup Configuration

To set up your personal user, characters, and rooms:

1. Copy the example file:
   ```bash
   cp jonathan_setup.yaml.example jonathan_setup.yaml
   ```

2. Edit `jonathan_setup.yaml` with your personal details:
   - Update user name, email, and preferences
   - Customize character personalities and descriptions
   - Modify room title and starting message
   - Adjust membership role

3. Run the seed script:
   ```elixir
   AshChat.DemoData.seed_jonathan_setup()
   ```

## Notes

- `*.yaml` files are gitignored (personal configuration)
- `*.yaml.example` files are tracked (templates)
- The seed script is idempotent - safe to run multiple times
- Configuration loads from `config/[name]_setup.yaml`