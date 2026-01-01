
# Status 
for dir in ./specs/*/; do feature=$(basename "$dir"); echo "=== $feature ==="; ls -la "$dir" | grep -E "spec\.md|plan\.md|tasks\.md|constitution\.md" || echo "No artifacts"; done

# 
 python3 << 'EOF'
   import os
   from pathlib import Path

   specs_dir = Path('./specs')
   features = {}

   for feature_dir in sorted(specs_dir.iterdir()):
       if feature_dir.is_dir():
           feature_name = feature_dir.name
           files = sorted([f.name for f in feature_dir.iterdir() if f.is_file()])
           features[feature_name] = files

   for feature, files in features.items():
       spec = 'spec.md' in files
       plan = 'plan.md' in files
       tasks = 'tasks.md' in files
       status = 'COMPLETE' if (spec and plan and tasks) else 'PARTIAL' if (spec and plan) else 'INCOMPLETE'
       print(f"{feature:30} [{status:10}] spec={spec} plan={plan} tasks={tasks}")
   EOF

# 
python3 << 'EOF'
   import subprocess
   import json

   # Get branch info
   result = subprocess.run(['git', 'branch', '-a', '-v', '--format=%(refname:short)|%(objectname:short)|%(upstream:short)|%(if)%(upstream)%(then)%(upstream:short)%(else)none%(end)'],
                          capture_output=True, text=True)

   branches = {}
   for line in result.stdout.strip().split('\n'):
       if line:
           parts = line.split('|')
           if len(parts) >= 4:
               name = parts[0].strip()
               commit = parts[1].strip()
               upstream = parts[3].strip() if len(parts) > 3 else 'none'
               branches[name] = {'commit': commit, 'upstream': upstream}

   # Categorize branches
   local_branches = {k: v for k, v in branches.items() if not k.startswith('origin/')}
   remote_branches = {k: v for k, v in branches.items() if k.startswith('origin/')}

   print("LOCAL BRANCHES:")
   for name in sorted(local_branches.keys()):
       upstream = local_branches[name]['upstream']
       print(f"  {name:40} -> {upstream}")

   print("\nREMOTE BRANCHES:")
   for name in sorted(remote_branches.keys()):
       clean_name = name.replace('origin/', '')
       print(f"  {clean_name:40} (remote)")
   EOF


# ---
 python3 << 'EOF'
   import subprocess

   # Get all tags
   result = subprocess.run(['git', 'tag', '-l'], capture_output=True, text=True)
   tags = result.stdout.strip().split('\n') if result.stdout.strip() else []

   print("TAGS:")
   for tag in sorted(tags):
       print(f"  {tag}")
   EOF
