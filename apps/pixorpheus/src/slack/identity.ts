/** Populated once at boot from auth.test(), read everywhere else. */
export const botIdentity: { userId: string | null; appId: string | null } = {
  userId: null,
  appId: null,
};

export function setBotIdentity(userId: string, appId: string): void {
  botIdentity.userId = userId;
  botIdentity.appId = appId;
}
