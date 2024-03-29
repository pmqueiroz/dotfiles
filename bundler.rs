use std::fs;
use std::env;
use std::collections::HashSet;
use std::io::{self};
use std::path::{Path, PathBuf};

fn main() -> io::Result<()> {
  let args: Vec<String> = env::args().collect();
  if args.len() != 3 {
    eprintln!("Usage: bundler <input_script.sh> <output_script.sh>");
    std::process::exit(1);
  }

  let input_script = &args[1];
  let output_file = &args[2];

  let mut processed_files = HashSet::new();
  let mut output = Vec::new();

  process_script(input_script, &mut processed_files, &mut output)?;
  fs::write(output_file, output.join("\n"))?;

  Ok(())
}

fn process_script(file_path: &str, processed_files: &mut HashSet<String>, output: &mut Vec<String>) -> io::Result<()> {
  println!("Processing: {}", file_path);

  if processed_files.contains(file_path) {
    return Ok(());
  }

  processed_files.insert(file_path.to_string());
  let content = fs::read_to_string(file_path)?;

  let parent_path = Path::new(file_path).parent().unwrap_or_else(|| Path::new(""));

  for line in content.lines() {
    if line.starts_with("#") {
      continue;
    }

    if line.starts_with("source ") || line.starts_with(". ") {
      let imported_file = line.split_whitespace().nth(1).unwrap();
  
      if !imported_file.starts_with("$HOME") {
        let full_path = PathBuf::from(parent_path).join(imported_file);
        process_script(&full_path.to_string_lossy(), processed_files, output)?;
      } else {
        output.push(line.to_string());
      }
    } else {
      output.push(line.to_string());
    }
  }

  Ok(())
}
