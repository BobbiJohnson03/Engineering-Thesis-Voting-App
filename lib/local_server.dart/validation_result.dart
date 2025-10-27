class ValidationResult {
  final bool ok;
  final String? error;
  const ValidationResult.ok() : ok = true, error = null;
  const ValidationResult.err(this.error) : ok = false;
}
