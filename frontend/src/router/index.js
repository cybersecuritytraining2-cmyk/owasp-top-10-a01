import { createRouter, createWebHistory } from "vue-router";
import LoginView from "@/views/LoginView.vue";
import DashboardView from "@/views/DashboardView.vue";
import AdminView from "@/views/AdminView.vue";

const routes = [
  { path: "/", redirect: "/dashboard" },
  { path: "/login", component: LoginView },
  { path: "/dashboard", component: DashboardView },
  // Internal operations console. Staff only — not shown in the customer nav.
  { path: "/admin", component: AdminView },
];

const router = createRouter({
  history: createWebHistory(),
  routes,
});

// Send unauthenticated visitors to the login screen.
router.beforeEach((to) => {
  const authed = !!localStorage.getItem("vs_token");
  if (!authed && to.path !== "/login") return "/login";
  if (authed && to.path === "/login") return "/dashboard";
});

export default router;
