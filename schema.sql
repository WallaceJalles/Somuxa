-- Somaí: banco de dados do casal (Supabase / PostgreSQL)
-- Cole este arquivo inteiro no SQL Editor do Supabase e clique em Run.
-- Pode rodar de novo sem medo: ele não apaga dados existentes.

-- 1) Tabelas ---------------------------------------------------------------

create table if not exists public.casais (
  id        uuid primary key default gen_random_uuid(),
  codigo    text not null unique,
  criado_em timestamptz not null default now()
);

create table if not exists public.membros (
  casal_id uuid not null references public.casais(id) on delete cascade,
  user_id  uuid not null references auth.users(id) on delete cascade,
  primary key (casal_id, user_id)
);

-- cada conta pertence a um único casal
create unique index if not exists membros_user_unico on public.membros (user_id);

-- os dados do app: uma linha por configuração ('config') e por mês ('m:2026-11')
create table if not exists public.estado (
  casal_id      uuid not null references public.casais(id) on delete cascade,
  chave         text not null,
  dados         jsonb not null,
  atualizado_em timestamptz not null default now(),
  primary key (casal_id, chave)
);

-- 2) Função auxiliar: qual é o casal de quem está logado -------------------

create or replace function public.meu_casal()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select casal_id from public.membros where user_id = auth.uid() limit 1
$$;

-- 3) Segurança (RLS): cada casal só enxerga e altera os próprios dados ------

alter table public.casais  enable row level security;
alter table public.membros enable row level security;
alter table public.estado  enable row level security;

drop policy if exists casais_ler   on public.casais;
drop policy if exists membros_ler  on public.membros;
drop policy if exists estado_tudo  on public.estado;

create policy casais_ler  on public.casais  for select to authenticated using (id = public.meu_casal());
create policy membros_ler on public.membros for select to authenticated using (casal_id = public.meu_casal());
create policy estado_tudo on public.estado  for all    to authenticated
  using (casal_id = public.meu_casal())
  with check (casal_id = public.meu_casal());

-- ninguém sem login acessa nada
revoke all on public.casais  from anon;
revoke all on public.membros from anon;
revoke all on public.estado  from anon;

-- criar e entrar em casal só acontecem pelas funções abaixo
revoke insert, update, delete on public.casais  from authenticated;
revoke insert, update, delete on public.membros from authenticated;

-- Permissões da API: projetos novos do Supabase não liberam as tabelas sozinhos.
-- Sem estas linhas o app mostra o erro 42501 "permission denied for table casais".
grant usage on schema public to authenticated;
grant select on public.casais  to authenticated;
grant select on public.membros to authenticated;
grant select, insert, update, delete on public.estado to authenticated;

-- 4) Criar o casal (gera um código para o parceiro(a)) ----------------------

create or replace function public.criar_casal()
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_id  uuid;
  v_cod text;
begin
  if v_uid is null then
    raise exception 'nao_autenticado';
  end if;
  if exists (select 1 from public.membros where user_id = v_uid) then
    raise exception 'ja_tem_casal';
  end if;
  loop
    v_cod := upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 10));
    exit when not exists (select 1 from public.casais where codigo = v_cod);
  end loop;
  insert into public.casais (codigo) values (v_cod) returning id into v_id;
  insert into public.membros (casal_id, user_id) values (v_id, v_uid);
  return v_cod;
end;
$$;

-- 5) Entrar no grupo com o código (máximo de quatro pessoas) ------------------

create or replace function public.entrar_casal(p_codigo text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_id  uuid;
  v_n   int;
begin
  if v_uid is null then
    raise exception 'nao_autenticado';
  end if;
  if exists (select 1 from public.membros where user_id = v_uid) then
    raise exception 'ja_tem_casal';
  end if;
  select id into v_id from public.casais
   where codigo = upper(replace(replace(trim(p_codigo), '-', ''), ' ', ''));
  if v_id is null then
    raise exception 'codigo_invalido';
  end if;
  select count(*) into v_n from public.membros where casal_id = v_id;
  if v_n >= 4 then
    raise exception 'casal_cheio';
  end if;
  insert into public.membros (casal_id, user_id) values (v_id, v_uid);
  return true;
end;
$$;

revoke execute on function public.criar_casal()        from public, anon;
revoke execute on function public.entrar_casal(text)   from public, anon;
revoke execute on function public.meu_casal()          from public, anon;
grant  execute on function public.criar_casal()        to authenticated;
grant  execute on function public.entrar_casal(text)   to authenticated;
grant  execute on function public.meu_casal()          to authenticated;

-- 6) Atualização ao vivo entre os aparelhos ---------------------------------

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
     where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'estado'
  ) then
    alter publication supabase_realtime add table public.estado;
  end if;
end
$$;
