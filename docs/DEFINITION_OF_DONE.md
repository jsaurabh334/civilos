# CivilOS Definition of Done (DoD)

Before any module (Projects, Tender, Inventory, Finance, etc.) is considered **Complete** and merged into production, it MUST satisfy the following criteria. This discipline ensures consistent quality, prevents technical debt, and stops partially finished modules from accumulating.

### Minimum Criteria Checklist

- [ ] **Backend implemented**: All required REST APIs, controllers, services, and repositories are structured in the modular feature-based architecture (`backend/internal/modules/`).
- [ ] **Database complete**: GORM models are defined, foreign keys established, constraints set, and any necessary migrations are accounted for.
- [ ] **APIs documented**: Endpoints, payloads, and response structures are documented (e.g., Swagger/OpenAPI, or consistent code-level documentation).
- [ ] **UI complete**: The Flutter frontend accurately reflects the premium design aesthetic (Glassmorphism, Micro-animations, Dark/Light modes).
- [ ] **Responsive on web/mobile**: Layouts automatically adjust for mobile (`iOS`/`Android`) screens and wide desktop viewports (`Web`).
- [ ] **Role permissions enforced**: Role-based access control (RBAC) is strictly enforced at the backend level (Super Admin, Contractor Owner, Project Manager) and hidden conditionally on the frontend UI.
- [ ] **Validation complete**: Strict data validation is implemented on both the frontend forms and the backend handlers.
- [ ] **Loading/empty/error states handled**: No infinite spinners. The UI provides clear feedback for loading states, empty lists, and error popups/snackbars.
- [ ] **Audit logs recorded**: Action logs (who did what and when) are recorded in the database for sensitive operations.
- [ ] **Notifications integrated**: Relevant users receive push notifications or in-app alerts triggered by module actions.
- [ ] **Tested**: Essential unit tests, edge cases, and manual verifications have passed successfully.
- [ ] **Reviewed**: The code has been reviewed by the team and approved.
- [ ] **Production-ready**: No placeholder code or generic colors; ready for end-user App Store deployment.
