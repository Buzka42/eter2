/// What the user chose. Persisted, mirrored to Firestore, and validated by
/// `firestore.rules` against exactly these three names — do not rename them
/// without changing the rules in the same commit.
///
/// This is the *setting*, not the appearance. What actually renders is
/// [EterRegister], which [GuidanceMode.balanced] resolves by the sun. See
/// `core/register.dart`.
enum GuidanceMode { grounded, balanced, immersive }
