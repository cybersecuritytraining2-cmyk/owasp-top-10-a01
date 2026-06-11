<script setup>
import { ref } from "vue";
import { useRouter } from "vue-router";
import { login } from "@/services/api.js";

const router = useRouter();
const username = ref("");
const password = ref("");
const error = ref("");
const loading = ref(false);

async function submit() {
  error.value = "";
  loading.value = true;
  try {
    const { data } = await login(username.value, password.value);
    localStorage.setItem("vs_token", data.token);
    localStorage.setItem("vs_name", data.user.name);
    localStorage.setItem("vs_account", data.user.account_number);
    router.push("/dashboard");
  } catch (e) {
    error.value = e.response?.data?.error || "Unable to sign in.";
  } finally {
    loading.value = false;
  }
}
</script>

<template>
  <section class="max-w-md mx-auto px-5 py-16">
    <div class="text-center mb-8">
      <span class="inline-grid place-items-center w-14 h-14 rounded-xl bg-brand text-white font-bold text-xl mb-4">VS</span>
      <h1 class="text-2xl font-bold text-text">Sign in to Online Banking</h1>
      <p class="text-sub mt-2 text-sm">Secure access to your Vault Street accounts.</p>
    </div>

    <form @submit.prevent="submit" class="bg-card border border-line rounded-2xl p-6 space-y-4">
      <div>
        <label class="block text-sm text-sub mb-1.5">Username</label>
        <input
          v-model="username"
          autocomplete="username"
          class="w-full bg-ink border border-line rounded-lg px-3 py-2.5 text-text focus:border-brand outline-none"
          placeholder="e.g. alice"
        />
      </div>
      <div>
        <label class="block text-sm text-sub mb-1.5">Password</label>
        <input
          v-model="password"
          type="password"
          autocomplete="current-password"
          class="w-full bg-ink border border-line rounded-lg px-3 py-2.5 text-text focus:border-brand outline-none"
          placeholder="••••••••"
        />
      </div>

      <p v-if="error" class="text-neg text-sm">{{ error }}</p>

      <button
        type="submit"
        :disabled="loading"
        class="w-full bg-brand hover:bg-brand-dark disabled:opacity-60 text-white font-semibold py-2.5 rounded-lg transition"
      >
        {{ loading ? "Signing in…" : "Sign in" }}
      </button>
    </form>

    <div class="bg-card2/50 border border-line rounded-xl p-4 mt-6 text-sm">
      <p class="text-sub font-medium mb-2">Demo customer logins</p>
      <ul class="text-sub/80 space-y-1 font-mono text-xs">
        <li>alice / Spring2024!</li>
        <li>bob / Hunter2024#</li>
        <li>carol / Autumn2024$</li>
      </ul>
    </div>
  </section>
</template>
