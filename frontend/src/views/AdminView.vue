<script setup>
import { ref, onMounted } from "vue";
import {
  adminLogs,
  adminTransactions,
  adminUsers,
  adminBlock,
  adminUnblock,
} from "@/services/api.js";

const logs = ref([]);
const transactions = ref([]);
const users = ref([]);
const error = ref("");
const tab = ref("logs");

const money = (n) =>
  new Intl.NumberFormat("en-US", { style: "currency", currency: "USD" }).format(n);

onMounted(load);

async function load() {
  error.value = "";
  try {
    const [l, t, u] = await Promise.all([adminLogs(), adminTransactions(), adminUsers()]);
    logs.value = l.data.logs;
    transactions.value = t.data.transactions;
    users.value = u.data.users;
  } catch (e) {
    error.value = e.response?.data?.error || "Could not load the operations console.";
  }
}

async function toggleBlock(u) {
  try {
    if (u.blocked) await adminUnblock(u.id);
    else await adminBlock(u.id);
    await load();
  } catch (e) {
    error.value = e.response?.data?.error || "Action failed.";
  }
}
</script>

<template>
  <section class="max-w-5xl mx-auto px-5 py-8">
    <div class="flex items-center gap-3 mb-6">
      <span class="grid place-items-center w-9 h-9 rounded-lg bg-gold text-ink font-bold">OPS</span>
      <div>
        <h1 class="text-2xl font-bold text-text">Operations Console</h1>
        <p class="text-sub text-sm">Internal monitoring &amp; account administration</p>
      </div>
    </div>

    <p v-if="error" class="bg-neg/10 border border-neg/40 text-neg rounded-xl p-4 mb-6 text-sm">{{ error }}</p>

    <div class="flex gap-2 mb-5">
      <button
        v-for="t in ['logs', 'transactions', 'users']"
        :key="t"
        @click="tab = t"
        class="px-4 py-2 rounded-lg text-sm capitalize transition border"
        :class="tab === t ? 'bg-brand border-brand text-white' : 'bg-card border-line text-sub hover:text-text'"
      >
        {{ t }}
      </button>
    </div>

    <!-- Logs -->
    <div v-if="tab === 'logs'" class="bg-ink border border-line rounded-2xl p-4">
      <pre class="text-xs text-sub font-mono whitespace-pre-wrap leading-relaxed">{{ logs.join("\n") }}</pre>
    </div>

    <!-- Transactions -->
    <div v-else-if="tab === 'transactions'" class="bg-card border border-line rounded-2xl p-6 overflow-x-auto">
      <table class="w-full text-sm">
        <thead>
          <tr class="text-sub/70 text-left border-b border-line">
            <th class="py-2 font-medium">Date</th>
            <th class="py-2 font-medium">Account</th>
            <th class="py-2 font-medium">Description</th>
            <th class="py-2 font-medium text-right">Amount</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="t in transactions" :key="t.id" class="border-b border-line/50">
            <td class="py-2 text-sub whitespace-nowrap">{{ t.created_at.slice(0, 10) }}</td>
            <td class="py-2 font-mono text-sub">{{ t.account_number }}</td>
            <td class="py-2 text-text">{{ t.description }}</td>
            <td class="py-2 text-right font-mono" :class="t.amount < 0 ? 'text-neg' : 'text-pos'">
              {{ t.amount < 0 ? "-" : "+" }}{{ money(Math.abs(t.amount)) }}
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Users -->
    <div v-else class="bg-card border border-line rounded-2xl p-6 overflow-x-auto">
      <table class="w-full text-sm">
        <thead>
          <tr class="text-sub/70 text-left border-b border-line">
            <th class="py-2 font-medium">Name</th>
            <th class="py-2 font-medium">Account</th>
            <th class="py-2 font-medium">Role</th>
            <th class="py-2 font-medium text-right">Balance</th>
            <th class="py-2 font-medium text-right">Status</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="u in users" :key="u.id" class="border-b border-line/50">
            <td class="py-2 text-text">{{ u.name }}</td>
            <td class="py-2 font-mono text-sub">{{ u.account_number }}</td>
            <td class="py-2 text-sub capitalize">{{ u.role }}</td>
            <td class="py-2 text-right font-mono text-sub">{{ money(u.balance) }}</td>
            <td class="py-2 text-right">
              <button
                @click="toggleBlock(u)"
                class="text-xs rounded-lg px-3 py-1.5 border transition"
                :class="u.blocked
                  ? 'border-pos/50 text-pos hover:bg-pos/10'
                  : 'border-neg/50 text-neg hover:bg-neg/10'"
              >
                {{ u.blocked ? "Unblock" : "Block" }}
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </section>
</template>
