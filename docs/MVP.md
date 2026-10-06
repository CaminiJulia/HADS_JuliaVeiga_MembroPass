# Definição do MVP — MembroPass

Referência: DVP v2.6 (`docs/dvp/MembroPass_DVP_v2_6.pdf`).

O DVP prevê 11 semanas de codificação. A disciplina tem cerca de 8 semanas até a entrega
(23/11/2026), por isso o escopo foi reduzido ao fluxo central do produto: **a organização configura
o programa e cadastra o membro, o membro apresenta a carteirinha e o operador valida o check-in.**

## Dentro do MVP

| Requisito | Escopo no MVP |
|---|---|
| RF01 Gerenciar Login | Login por e-mail e senha nos três cadastros (administrador, operador, membro), hash forte da senha, bloqueio temporário após tentativas inválidas, unicidade do e-mail entre os três cadastros |
| RF02 Gerenciar Perfis | Controle de acesso por papel e por organização; cada papel abre a sua área do app |
| RF03 Gerenciar Organização | Cadastro da organização com status "em habilitação". A habilitação é externa ao app (feita direto no banco, como prevê o DVP) |
| RF04 Planos de Associação | CRUD de planos com valor de referência e duração do ciclo; desativação sem afetar membros vinculados |
| RF05 Carteirinha Digital | Emissão automática ao vincular o membro a um plano; QR Code assinado e não sequencial; status ativo, vencendo em breve ou vencido |
| RF06 Gerenciar Membros | Cadastro, edição e desativação de membros pelo administrador |
| RF07 Liberar Ciclo e Bloquear | Confirmação manual de pagamento com cálculo do novo vencimento; bloqueio manual; nenhuma ação automática |
| RF08 Benefícios | CRUD de benefícios com vigência e vínculo N:M com planos |
| RF09 Consultar Benefícios | Membro vê os benefícios vigentes do seu plano |
| RF10 Check-in via QR Code | Leitura do QR pelo operador, validação de ciclo, bloqueio e plano aceito; registro de tentativas aprovadas e rejeitadas |
| RF11 Unidades e Eventos | CRUD de unidades e eventos com planos aceitos |
| RF16 Auditoria | Registro imutável de liberação, bloqueio, desativação e edição de plano |
| RF17 White-label | Upload do logotipo, escolha de cor com verificação de contraste, pré-visualização e aplicação a todas as carteirinhas |
| RF18 Canal de Suporte | Exibição dos dados de contato do suporte no painel do administrador |

## Fora do MVP (implementar se sobrar tempo, nesta ordem)

1. RF12 Histórico de check-ins (membro e administrador)
2. RF14 Cancelamento de associação
3. RF15 Relatórios gerenciais
4. RF13 Notificações
5. Funcionalidades adicionais do RF01: recuperação de senha e confirmação por e-mail
6. RNF05 Carteirinha offline
7. Autocadastro do membro por link de adesão (RF06)
8. Rotação periódica do QR Code (RNF08). No MVP o QR já é assinado e tem versão, e a versão muda a
   cada liberação ou bloqueio.

## Requisitos exigidos pela disciplina

- Script SQL de criação do banco, dados de teste e regras de negócio com triggers e procedures (`database/`)
- Diagrama de casos de uso e diagrama de classes dos casos de uso implementados
- Diagrama de componentes da arquitetura
- Testes unitários (caixa-branca) dos objetos de domínio e testes funcionais (caixa-preta) dos casos de uso
- Atualização semanal do repositório e do `docs/STATUS.md`
