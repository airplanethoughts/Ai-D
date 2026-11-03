/// Capabilities provisioned for this build; no billing is enabled by these flags.
class DeploymentFeatures {
  static const aiEnabled = bool.fromEnvironment(
    'ENABLE_AI',
    defaultValue: true,
  );
  static const uploadsEnabled = bool.fromEnvironment(
    'ENABLE_UPLOADS',
    defaultValue: true,
  );
}
